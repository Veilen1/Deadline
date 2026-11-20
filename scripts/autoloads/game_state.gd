extends Node
## Estado global de la run y la meta-progresión.
## Responsabilidad única: almacenar y exponer estado.
## No spawnea enemigos, no maneja zonas y no conoce escenas.

signal money_changed(new_amount: int)
signal timer_changed(remaining: float)
signal run_started
signal run_ended(reason: String)

const VALID_END_REASONS: PackedStringArray = ["timer", "death", "completed"]
const DEFAULT_SAVE_PATH: String = "user://deadline_progress.cfg"
const SAVE_VERSION: int = 1
const SAVE_DEBOUNCE: float = 0.5

# Tiempo base por defecto, antes de mejoras.
@export var default_run_time: float = 60.0

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
var unlocked_skills: Array[String] = ["root"]
var skill_bonuses: Dictionary = {}

# Armas desbloqueadas y equipada.
var owned_weapons: Array[String] = ["basic_rifle"]
var equipped_weapon: String = "basic_rifle"

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

	load_game()


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


func is_skill_unlocked(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id)


func is_skill_available(skill_id: String) -> bool:
	if is_skill_unlocked(skill_id):
		return false

	var data: Dictionary = SkillTree.get_node_data(skill_id)
	if data.is_empty():
		return false

	for required in data.get("requires", []):
		if unlocked_skills.has(str(required)):
			return true
	return false


func can_unlock_skill(skill_id: String) -> bool:
	if not is_skill_available(skill_id):
		return false

	var data: Dictionary = SkillTree.get_node_data(skill_id)
	return money >= int(data.get("cost", 0))


func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false

	var data: Dictionary = SkillTree.get_node_data(skill_id)
	var cost: int = int(data.get("cost", 0))
	if not spend_money(cost):
		return false

	unlocked_skills.append(skill_id)

	var effects: Dictionary = data.get("effects", {})
	for key in effects:
		var value: float = float(effects[key])
		skill_bonuses[key] = float(skill_bonuses.get(key, 0.0)) + value

	if effects.has("time_bonus"):
		add_run_time(float(effects["time_bonus"]))

	save_game()
	return true


func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount


func spend_money(amount: int) -> bool:
	if amount < 0 or money < amount:
		return false
	money -= amount
	return true


func start_run() -> void:
	is_run_active = true
	run_start_money = money
	last_death_penalty = 0
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
	else:
		last_death_penalty = 0
	is_run_active = false

	# TODO: Fase 2.4 — aplicar consecuencias específicas por motivo.
	if not VALID_END_REASONS.has(reason):
		push_warning("GameState.end_run: motivo desconocido '%s'" % reason)
	run_ended.emit(reason)
	save_game()


func abandon_run() -> void:
	# Salir de la run desde la pausa cuenta como muerte.
	if not is_run_active:
		return

	_apply_death_penalty()
	is_run_active = false
	save_game()


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


func reset_progress() -> void:
	# Borra plata, mejoras y tiempo comprado. Deja el guardado en cero.
	_is_loading = true
	money = 0
	upgrades.clear()
	base_run_time = default_run_time
	is_run_active = false
	run_timer = base_run_time
	run_start_money = 0
	last_death_penalty = 0
	unlocked_skills.clear()
	unlocked_skills.append(SkillTree.ROOT_ID)
	skill_bonuses.clear()
	owned_weapons.clear()
	owned_weapons.append("basic_rifle")
	equipped_weapon = "basic_rifle"
	_is_loading = false
	save_game()


func save_game() -> void:
	if not persistence_enabled:
		return

	var config := ConfigFile.new()
	config.set_value("progress", "version", SAVE_VERSION)
	config.set_value("progress", "money", money)
	config.set_value("progress", "base_run_time", base_run_time)
	config.set_value("progress", "upgrades", upgrades)
	config.set_value("progress", "unlocked_skills", unlocked_skills)
	config.set_value("progress", "skill_bonuses", skill_bonuses)
	config.set_value("progress", "owned_weapons", owned_weapons)
	config.set_value("progress", "equipped_weapon", equipped_weapon)

	var error: int = config.save(save_path)
	if error != OK:
		push_warning("GameState: no se pudo guardar el progreso (%s)" % error)


func load_game() -> void:
	if not persistence_enabled:
		return

	var config := ConfigFile.new()
	var error: int = config.load(save_path)
	if error != OK:
		return

	_is_loading = true
	money = int(config.get_value("progress", "money", 0))

	var saved_time: float = float(config.get_value("progress", "base_run_time", default_run_time))
	base_run_time = saved_time if saved_time > 0.0 else default_run_time

	var saved_upgrades = config.get_value("progress", "upgrades", {})
	upgrades = saved_upgrades.duplicate() if saved_upgrades is Dictionary else {}

	var saved_skills = config.get_value("progress", "unlocked_skills", ["root"])
	unlocked_skills.clear()
	if saved_skills is Array:
		for skill_id in saved_skills:
			unlocked_skills.append(str(skill_id))
	elif saved_skills is PackedStringArray:
		for skill_id in saved_skills:
			unlocked_skills.append(str(skill_id))
	if not unlocked_skills.has(SkillTree.ROOT_ID):
		unlocked_skills.push_front(SkillTree.ROOT_ID)

	var saved_bonuses = config.get_value("progress", "skill_bonuses", {})
	skill_bonuses = saved_bonuses.duplicate() if saved_bonuses is Dictionary else {}

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

	_is_loading = false


func _queue_save() -> void:
	if not persistence_enabled or _is_loading or _save_timer == null:
		return
	_save_timer.start()


func _exit_tree() -> void:
	# Si se cierra el juego en plena run, también cuenta como abandono.
	if is_run_active:
		_apply_death_penalty()
		is_run_active = false

	# Último intento de guardado al cerrar el juego.
	save_game()
