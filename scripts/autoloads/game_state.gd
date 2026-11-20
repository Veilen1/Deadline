extends Node
## Estado global de la run y la meta-progresión.
## Responsabilidad única: almacenar y exponer estado.
## No spawnea enemigos, no maneja zonas y no conoce escenas.

signal money_changed(new_amount: int)
signal cores_changed(new_amount: int)
signal challenges_changed
signal timer_changed(remaining: float)
signal run_started
signal run_ended(reason: String)

const VALID_END_REASONS: PackedStringArray = ["timer", "death", "completed"]
const DEFAULT_SAVE_PATH: String = "user://deadline_progress.cfg"
const SAVE_VERSION: int = 3
const SAVE_DEBOUNCE: float = 0.5
const SKILL_COST_GROWTH: float = 1.35

# Tiempo base por defecto, antes de mejoras.
@export var default_run_time: float = 50.0

# Fracción de la plata recaudada en la run que se pierde al morir o abandonar.
@export var death_penalty: float = 0.30

# Ruta y switch de persistencia. Los tests pueden usar una ruta temporal.
var save_path: String = DEFAULT_SAVE_PATH
var persistence_enabled: bool = true

# Tiempo base de la run, ampliable desde el hub.
var base_run_time: float = 60.0

# Plata persistente entre runs. El setter emite la señal al cambiar.
var money: int = 0:
	set(value):
		var clamped_value: int = maxi(value, 0)
		if clamped_value == money:
			return
		money = clamped_value
		money_changed.emit(money)
		_queue_save()

# Núcleos: moneda exclusiva del árbol de habilidades.
var cores: int = 0:
	set(value):
		var clamped_value: int = maxi(value, 0)
		if clamped_value == cores:
			return
		cores = clamped_value
		cores_changed.emit(cores)
		challenges_changed.emit()
		_queue_save()

# True mientras la run está en curso. Evita emitir run_ended más de una vez.
var is_run_active: bool = false

# Tiempo restante de la run actual.
var run_timer: float = 0.0

# Plata al empezar la run, para calcular lo recaudado y la penalización.
var run_start_money: int = 0
var last_death_penalty: int = 0

# Mejoras compradas. Persisten entre runs.
var upgrades: Dictionary = {}

# Árbol de habilidades.
var skill_levels: Dictionary = {}
var skill_bonuses: Dictionary = {}

# Armas desbloqueadas y equipada.
var owned_weapons: Array[String] = ["basic_rifle"]
var equipped_weapon: String = "basic_rifle"

# Perfil del jugador.
var profile_name: String = "Jugador"
var runs_started: int = 0
var runs_completed: int = 0
var runs_timed_out: int = 0
var deaths: int = 0
var kills: int = 0
var lifetime_earned: int = 0

# Estadísticas de desafíos.
var headshots: int = 0
var elites_killed: int = 0
var hounds_killed: int = 0
var zones_cleared: int = 0
var claimed_challenges: Array[String] = []

var _save_timer: Timer
var _is_loading: bool = false


func _ready() -> void:
	base_run_time = default_run_time

	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DEBOUNCE
	_save_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_save_timer.timeout.connect(save_game)
	add_child(_save_timer)

	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.enemy_hit.connect(_on_enemy_hit)
	load_game()


func _on_enemy_killed(enemy: Node, _hit_zone: String) -> void:
	kills += 1
	if enemy != null and is_instance_valid(enemy):
		if enemy.is_in_group("elites"):
			elites_killed += 1
			add_cores(1)
		if enemy.is_in_group("hound_enemies"):
			hounds_killed += 1
	challenges_changed.emit()
	_queue_save()


func _on_enemy_hit(_enemy: Node, hit_zone: String, _damage: float, _money: int) -> void:
	if hit_zone != "head":
		return
	headshots += 1
	challenges_changed.emit()
	_queue_save()


func add_cores(amount: int) -> void:
	if amount > 0:
		cores += amount


func spend_cores(amount: int) -> bool:
	if amount < 0 or cores < amount:
		return false
	cores -= amount
	return true


func convert_money_to_core() -> bool:
	# Cambio pensado para darle uso a la plata cuando ya tenés las armas.
	const CONVERSION_PRICE: int = 250
	if not spend_money(CONVERSION_PRICE):
		return false
	add_cores(1)
	return true


func register_zone_cleared() -> void:
	zones_cleared += 1
	add_cores(1)
	challenges_changed.emit()
	_queue_save()


func is_weapon_unlocked(weapon_id: String) -> bool:
	if weapon_id == "basic_rifle" or is_weapon_owned(weapon_id):
		return true
	var challenge_id: String = ChallengeRegistry.weapon_unlock_for(weapon_id)
	if challenge_id.is_empty():
		return true
	return is_challenge_completed(challenge_id)


func is_weapon_challenge(weapon_id: String) -> bool:
	return not ChallengeRegistry.weapon_unlock_for(weapon_id).is_empty()


func get_challenge_progress(challenge_id: String) -> int:
	var data: Dictionary = ChallengeRegistry.get_data(challenge_id)
	if data.is_empty():
		return 0
	var target: int = int(data.get("target", 1))
	return mini(stat_value(str(data.get("stat", ""))), target)


func is_challenge_completed(challenge_id: String) -> bool:
	var data: Dictionary = ChallengeRegistry.get_data(challenge_id)
	if data.is_empty():
		return false
	return get_challenge_progress(challenge_id) >= int(data.get("target", 1))


func is_challenge_claimed(challenge_id: String) -> bool:
	return claimed_challenges.has(challenge_id)


func claim_challenge(challenge_id: String) -> bool:
	if not is_challenge_completed(challenge_id) or is_challenge_claimed(challenge_id):
		return false
	var data: Dictionary = ChallengeRegistry.get_data(challenge_id)
	if str(data.get("reward_type", "")) != "cores":
		return false
	add_cores(int(data.get("reward_id", "0")))
	claimed_challenges.append(challenge_id)
	challenges_changed.emit()
	save_game()
	return true


func stat_value(stat: String) -> int:
	match stat:
		"headshots":
			return headshots
		"kills":
			return kills
		"elites_killed":
			return elites_killed
		"hounds_killed":
			return hounds_killed
		"zones_cleared":
			return zones_cleared
		"runs_completed":
			return runs_completed
		"runs_started":
			return runs_started
		_:
			return 0


func add_run_time(seconds: float) -> void:
	base_run_time += seconds
	_queue_save()


func register_upgrade(upgrade_id: String, bonus: float) -> void:
	# Guarda nivel y bonus acumulado para aplicarlo en cada run.
	var level_key: String = upgrade_id + "_level"
	var bonus_key: String = upgrade_id + "_bonus"
	upgrades[level_key] = int(upgrades.get(level_key, 0)) + 1
	upgrades[bonus_key] = float(upgrades.get(bonus_key, 0.0)) + bonus
	_queue_save()


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrades.get(upgrade_id + "_level", 0))


func is_weapon_owned(weapon_id: String) -> bool:
	return owned_weapons.has(weapon_id)


func buy_weapon(weapon_id: String) -> bool:
	if is_weapon_owned(weapon_id):
		return false
	if not is_weapon_unlocked(weapon_id):
		return false

	var data: WeaponData = WeaponRegistry.get_data(weapon_id)
	if data == null:
		return false
	if not spend_money(data.price):
		return false

	owned_weapons.append(weapon_id)
	save_game()
	return true


func equip_weapon(weapon_id: String) -> bool:
	if not is_weapon_owned(weapon_id):
		return false
	equipped_weapon = weapon_id
	save_game()
	return true


func get_skill_level(skill_id: String) -> int:
	return int(skill_levels.get(skill_id, 0))


func is_skill_unlocked(skill_id: String) -> bool:
	return get_skill_level(skill_id) > 0


func is_skill_available(skill_id: String) -> bool:
	var data: Dictionary = SkillTree.get_node_data(skill_id)
	if data.is_empty():
		return false

	var max_level: int = int(data.get("max_level", 1))
	if get_skill_level(skill_id) >= max_level:
		return false

	var requires: Array = data.get("requires", [])
	if requires.is_empty():
		return true

	for required in requires:
		if get_skill_level(str(required)) > 0:
			return true
	return false


func skill_cost(skill_id: String) -> int:
	var data: Dictionary = SkillTree.get_node_data(skill_id)
	if data.is_empty():
		return 0

	# Costo exponencial en núcleos: cada nivel sale más caro que el anterior.
	var base: int = int(data.get("base_cost", 1))
	var level: int = get_skill_level(skill_id)
	return maxi(1, int(ceil(float(base) * pow(SKILL_COST_GROWTH, float(level)))))


func can_upgrade_skill(skill_id: String) -> bool:
	if not is_skill_available(skill_id):
		return false
	return cores >= skill_cost(skill_id)


func upgrade_skill(skill_id: String) -> bool:
	if not can_upgrade_skill(skill_id):
		return false

	var data: Dictionary = SkillTree.get_node_data(skill_id)
	var cost: int = skill_cost(skill_id)
	if not spend_cores(cost):
		return false

	skill_levels[skill_id] = get_skill_level(skill_id) + 1

	var effects: Dictionary = data.get("effects", {})
	for key in effects:
		var value: float = float(effects[key])
		skill_bonuses[key] = float(skill_bonuses.get(key, 0.0)) + value

	if effects.has("time_bonus"):
		add_run_time(float(effects["time_bonus"]))

	save_game()
	return true


func get_unlocked_skill_count() -> int:
	var count: int = 0
	for level in skill_levels.values():
		if int(level) > 0:
			count += 1
	return count


func _apply_all_skill_effects() -> void:
	skill_bonuses.clear()
	for skill_id in skill_levels:
		var level: int = get_skill_level(str(skill_id))
		if level <= 0:
			continue

		var data: Dictionary = SkillTree.get_node_data(str(skill_id))
		var effects: Dictionary = data.get("effects", {})
		for key in effects:
			var value: float = float(effects[key]) * float(level)
			skill_bonuses[key] = float(skill_bonuses.get(key, 0.0)) + value
			if key == "time_bonus":
				add_run_time(float(effects[key]) * float(level))


func _migrate_old_skills(old_skills) -> Dictionary:
	var ids: Array = []
	if old_skills is Array:
		ids = old_skills
	elif old_skills is PackedStringArray:
		for raw_id in old_skills:
			ids.append(str(raw_id))

	var mapped: Dictionary = {}
	for raw_id in ids:
		match str(raw_id):
			"dmg_1":
				mapped["damage_core"] = maxi(int(mapped.get("damage_core", 0)), 1)
			"dmg_2":
				mapped["damage_core"] = maxi(int(mapped.get("damage_core", 0)), 2)
			"fire_rate_1":
				mapped["cadence"] = maxi(int(mapped.get("cadence", 0)), 1)
			"hp_1":
				mapped["vitality"] = maxi(int(mapped.get("vitality", 0)), 1)
			"hp_2":
				mapped["vitality"] = maxi(int(mapped.get("vitality", 0)), 2)
			"time_1":
				mapped["time"] = maxi(int(mapped.get("time", 0)), 1)
			"ammo_cap_1":
				mapped["extended_mag"] = maxi(int(mapped.get("extended_mag", 0)), 1)
			"ammo_regen_1":
				mapped["regen"] = maxi(int(mapped.get("regen", 0)), 1)
			_:
				pass

	if not ids.is_empty() and not mapped.has("damage_core"):
		mapped["damage_core"] = 1

	return mapped


func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	lifetime_earned += amount


func spend_money(amount: int) -> bool:
	if amount < 0 or money < amount:
		return false
	money -= amount
	return true


func start_run() -> void:
	is_run_active = true
	run_start_money = money
	last_death_penalty = 0
	runs_started += 1
	run_timer = base_run_time
	timer_changed.emit(run_timer)
	run_started.emit()


func tick_run(delta: float) -> void:
	# Avanza el temporizador y notifica. No tickea si la run ya terminó.
	if not is_run_active or run_timer <= 0.0:
		return

	run_timer = maxf(run_timer - delta, 0.0)
	timer_changed.emit(run_timer)

	if run_timer <= 0.0:
		end_run("timer")


func end_run(reason: String) -> void:
	# Ignora llamadas repetidas (ej. muerte y timer en el mismo frame).
	if not is_run_active:
		return

	if reason == "death":
		_apply_death_penalty()
		deaths += 1
	elif reason == "completed":
		runs_completed += 1
		add_cores(3)
	elif reason == "timer":
		runs_timed_out += 1
	else:
		last_death_penalty = 0
	is_run_active = false
	challenges_changed.emit()

	# TODO: Fase 2.4 — aplicar consecuencias específicas por motivo.
	if not VALID_END_REASONS.has(reason):
		push_warning("GameState.end_run: motivo desconocido '%s'" % reason)
	run_ended.emit(reason)
	Diagnostics.mark("end_run", {"reason": reason, "money": money})
	# Guarda fuera del frame crítico para no demorar el menú de fin de run.
	save_game.call_deferred()


func abandon_run() -> void:
	# Salir de la run desde la pausa cuenta como muerte.
	if not is_run_active:
		return

	_apply_death_penalty()
	deaths += 1
	is_run_active = false
	save_game.call_deferred()


func _apply_death_penalty() -> void:
	last_death_penalty = get_abandon_penalty()
	if last_death_penalty > 0:
		money -= last_death_penalty


func get_run_earnings() -> int:
	if not is_run_active:
		return 0
	return maxi(money - run_start_money, 0)


func get_abandon_penalty() -> int:
	var earned: int = get_run_earnings()
	if earned <= 0:
		return 0

	var rate: float = clampf(death_penalty, 0.0, 1.0)
	return mini(int(round(float(earned) * rate)), money)


func reset_run() -> void:
	# Solo reinicia el estado de la run. money y upgrades persisten.
	is_run_active = false
	run_timer = base_run_time
	timer_changed.emit(run_timer)


func grant_run_time(seconds: float) -> void:
	# Bonus de tiempo al completar una zona. Se ignora fuera de una run.
	if not is_run_active or seconds <= 0.0:
		return
	run_timer += seconds
	timer_changed.emit(run_timer)


func reset_progress() -> void:
	# Borra plata, mejoras y tiempo comprado. Deja el guardado en cero.
	_is_loading = true
	money = 0
	cores = 0
	claimed_challenges.clear()
	headshots = 0
	elites_killed = 0
	hounds_killed = 0
	zones_cleared = 0
	upgrades.clear()
	base_run_time = default_run_time
	is_run_active = false
	run_timer = base_run_time
	run_start_money = 0
	last_death_penalty = 0
	skill_levels.clear()
	skill_bonuses.clear()
	owned_weapons.clear()
	owned_weapons.append("basic_rifle")
	equipped_weapon = "basic_rifle"
	profile_name = "Jugador"
	runs_started = 0
	runs_completed = 0
	runs_timed_out = 0
	deaths = 0
	kills = 0
	lifetime_earned = 0
	_is_loading = false
	save_game()


func save_game() -> void:
	if not persistence_enabled:
		return

	var started_ms: int = Time.get_ticks_msec()
	var config := ConfigFile.new()
	config.set_value("progress", "version", SAVE_VERSION)
	config.set_value("progress", "money", money)
	config.set_value("progress", "cores", cores)
	config.set_value("progress", "claimed_challenges", claimed_challenges)
	config.set_value("progress", "base_run_time", base_run_time)
	config.set_value("progress", "upgrades", upgrades)
	config.set_value("progress", "skill_levels", skill_levels)
	config.set_value("progress", "skill_bonuses", skill_bonuses)
	config.set_value("progress", "owned_weapons", owned_weapons)
	config.set_value("progress", "equipped_weapon", equipped_weapon)
	config.set_value("profile", "name", profile_name)
	config.set_value("profile", "runs_started", runs_started)
	config.set_value("profile", "runs_completed", runs_completed)
	config.set_value("profile", "runs_timed_out", runs_timed_out)
	config.set_value("profile", "deaths", deaths)
	config.set_value("profile", "kills", kills)
	config.set_value("profile", "headshots", headshots)
	config.set_value("profile", "elites_killed", elites_killed)
	config.set_value("profile", "hounds_killed", hounds_killed)
	config.set_value("profile", "zones_cleared", zones_cleared)
	config.set_value("profile", "lifetime_earned", lifetime_earned)

	var error: int = config.save(save_path)
	if error != OK:
		push_warning("GameState: no se pudo guardar el progreso (%s)" % error)
	var elapsed: int = Time.get_ticks_msec() - started_ms
	if elapsed >= 30:
		Diagnostics.mark("save_slow", {"ms": elapsed, "path": save_path})


func load_game() -> void:
	if not persistence_enabled:
		return

	var config := ConfigFile.new()
	var error: int = config.load(save_path)
	if error != OK:
		return

	_is_loading = true
	money = int(config.get_value("progress", "money", 0))
	cores = maxi(int(config.get_value("progress", "cores", 0)), 0)
	claimed_challenges.clear()
	var saved_claims = config.get_value("progress", "claimed_challenges", [])
	if saved_claims is Array or saved_claims is PackedStringArray:
		for claim in saved_claims:
			claimed_challenges.append(str(claim))

	var saved_time: float = float(config.get_value("progress", "base_run_time", default_run_time))
	base_run_time = saved_time if saved_time > 0.0 else default_run_time

	var saved_version: int = int(config.get_value("progress", "version", 1))
	if saved_version < 2:
		# v0.5: el timer base pasa de 60 a 50 s. Se conserva el tiempo comprado.
		base_run_time = maxf(default_run_time, base_run_time - 10.0)

	var saved_upgrades = config.get_value("progress", "upgrades", {})
	upgrades = saved_upgrades.duplicate() if saved_upgrades is Dictionary else {}

	var saved_levels = null
	if config.has_section_key("progress", "skill_levels"):
		saved_levels = config.get_value("progress", "skill_levels")

	if saved_levels is Dictionary:
		skill_levels = saved_levels.duplicate()
		var saved_bonuses = config.get_value("progress", "skill_bonuses", {})
		skill_bonuses = saved_bonuses.duplicate() if saved_bonuses is Dictionary else {}
	else:
		# Migración desde el árbol anterior de nodos únicos.
		var old_skills = config.get_value("progress", "unlocked_skills", [])
		var old_bonuses = config.get_value("progress", "skill_bonuses", {})
		var old_time: float = 0.0
		if old_bonuses is Dictionary:
			old_time = float(old_bonuses.get("time_bonus", 0.0))
		base_run_time = maxf(base_run_time - old_time, 1.0)
		skill_levels = _migrate_old_skills(old_skills)
		_apply_all_skill_effects()

	var saved_weapons = config.get_value("progress", "owned_weapons", ["basic_rifle"])
	owned_weapons.clear()
	if saved_weapons is Array:
		for weapon_id in saved_weapons:
			owned_weapons.append(str(weapon_id))
	elif saved_weapons is PackedStringArray:
		for weapon_id in saved_weapons:
			owned_weapons.append(str(weapon_id))
	if not owned_weapons.has("basic_rifle"):
		owned_weapons.push_front("basic_rifle")

	equipped_weapon = str(config.get_value("progress", "equipped_weapon", "basic_rifle"))
	if not owned_weapons.has(equipped_weapon):
		equipped_weapon = "basic_rifle"

	profile_name = str(config.get_value("profile", "name", "Jugador"))
	runs_started = maxi(int(config.get_value("profile", "runs_started", 0)), 0)
	runs_completed = maxi(int(config.get_value("profile", "runs_completed", 0)), 0)
	runs_timed_out = maxi(int(config.get_value("profile", "runs_timed_out", 0)), 0)
	deaths = maxi(int(config.get_value("profile", "deaths", 0)), 0)
	kills = maxi(int(config.get_value("profile", "kills", 0)), 0)
	headshots = maxi(int(config.get_value("profile", "headshots", 0)), 0)
	elites_killed = maxi(int(config.get_value("profile", "elites_killed", 0)), 0)
	hounds_killed = maxi(int(config.get_value("profile", "hounds_killed", 0)), 0)
	zones_cleared = maxi(int(config.get_value("profile", "zones_cleared", 0)), 0)
	lifetime_earned = maxi(int(config.get_value("profile", "lifetime_earned", 0)), 0)

	_is_loading = false
	challenges_changed.emit()


func _queue_save() -> void:
	if not persistence_enabled or _is_loading or _save_timer == null:
		return
	_save_timer.start()


func _exit_tree() -> void:
	# Si se cierra el juego en plena run, también cuenta como abandono.
	if is_run_active:
		_apply_death_penalty()
		deaths += 1
		is_run_active = false

	# Último intento de guardado al cerrar el juego.
	save_game()
