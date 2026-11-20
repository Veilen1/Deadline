extends Node3D

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/effects/damage_number.tscn")
const SPARK_BURST_SCENE: PackedScene = preload("res://scenes/effects/spark_burst.tscn")
const ZONE_SCENES = [
	preload("res://scenes/levels/zone_01.tscn"),
	preload("res://scenes/levels/zone_02.tscn"),
	preload("res://scenes/levels/zone_03.tscn"),
]

@export var zone_banner_hold: float = 1.2
@export var zone_time_bonus: float = 5.0

@onready var player: Node = $Player
@onready var zones_root: Node3D = $Zones
@onready var minimap: Control = $CanvasLayer/Minimap
@onready var money_label: Label = $CanvasLayer/MoneyLabel
@onready var zone_label: Label = $CanvasLayer/ZoneLabel
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var health_label: Label = $CanvasLayer/HealthLabel
@onready var ammo_label: Label = $CanvasLayer/AmmoLabel
@onready var ammo_bar: ProgressBar = $CanvasLayer/AmmoBar
@onready var weapon_label: Label = $CanvasLayer/WeaponLabel
@onready var dash_bar: ProgressBar = $CanvasLayer/DashBar
@onready var weapon_slots: RichTextLabel = $CanvasLayer/WeaponSlots
@onready var style_label: Label = $CanvasLayer/StyleLabel
@onready var style_bar: ProgressBar = $CanvasLayer/StyleBar
@onready var boss_label: Label = $CanvasLayer/BossLabel
@onready var boss_bar: ProgressBar = $CanvasLayer/BossBar
@onready var boss_hp_label: Label = $CanvasLayer/BossHpLabel
@onready var boss_panel: Panel = $CanvasLayer/PanelBoss
@onready var zone_banner: Label = $CanvasLayer/ZoneBanner
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var game_over_menu: Control = $CanvasLayer/GameOverMenu
@onready var blessing_panel: Control = $CanvasLayer/BlessingPanel
@onready var blessing_label: Label = $CanvasLayer/BlessingLabel

var _zone_index: int = 0
var _current_zone: Node3D
var _transitioning: bool = false
var _banner_tween: Tween


func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.timer_changed.connect(_on_timer_changed)
	GameState.run_ended.connect(_on_run_ended)
	EventBus.enemy_hit.connect(_on_enemy_hit)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.ammo_changed.connect(_on_ammo_changed)
	EventBus.weapon_changed.connect(_on_weapon_changed)
	EventBus.critical_hit.connect(_on_critical_hit)
	StyleSystem.style_changed.connect(_on_style_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.zone_completed.connect(_on_zone_completed)
	EventBus.damage_number_requested.connect(_on_damage_number_requested)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	Settings.settings_changed.connect(_on_settings_changed)
	var run_upgrades: Dictionary = GameState.upgrades.duplicate()
	for key in GameState.skill_bonuses:
		run_upgrades[key] = float(run_upgrades.get(key, 0.0)) + float(GameState.skill_bonuses[key])
	player.call("apply_meta_upgrades", run_upgrades)
	var player_weapon: WeaponData = player.get("weapon_data") as WeaponData
	if player_weapon != null:
		weapon_label.text = player_weapon.weapon_name
	_update_weapon_slots()
	_on_ammo_changed(int(player.get("current_ammo")), int(player.get("max_ammo")))
	minimap.visible = Settings.show_minimap
	_update_money_label(GameState.money)
	_update_health_label()
	_load_zone(_zone_index)
	GameState.start_run()
	GameState.apply_contract_start()
	_update_blessing_label()


func _process(delta: float) -> void:
	if not _transitioning:
		GameState.tick_run(delta)
	if player != null and is_instance_valid(player):
		var ratio: float = float(player.call("get_dash_cooldown_ratio"))
		dash_bar.value = ratio
		dash_bar.modulate = Color(1, 1, 1, 1) if ratio >= 1.0 else Color(0.75, 0.82, 0.9, 0.85)


func _on_money_changed(new_amount: int) -> void:
	_update_money_label(new_amount)


func _on_enemy_hit(_enemy: Node, _hit_zone: String, _damage: float, money_value: int) -> void:
	GameState.add_money(money_value)


func _on_timer_changed(remaining: float) -> void:
	timer_label.text = "%.1f s" % remaining


func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Oleada %d" % wave_number


func _on_zone_completed(_zone_id: String) -> void:
	if not GameState.is_run_active or _transitioning:
		return
	_transitioning = true
	Diagnostics.mark("zone_completed", {"zone": _zone_id, "index": _zone_index})

	if _zone_index + 1 >= ZONE_SCENES.size():
		GameState.end_run("completed")
		_transitioning = false
		return

	# Completar una zona premia con tiempo extra para la siguiente.
	GameState.grant_run_time(zone_time_bonus)
	await _choose_blessing()
	_advance_zone()


func _choose_blessing() -> void:
	# La elección se hace con el árbol pausado para que el timer no corra.
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var blessing_id: String = await blessing_panel.call("choose")
	GameState.add_blessing(blessing_id)
	player.call("apply_blessings")
	_update_blessing_label()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _update_blessing_label() -> void:
	var parts: Array[String] = []
	for id in GameState.run_blessings:
		var count: int = int(GameState.run_blessings[id])
		if count <= 0:
			continue
		var data: Dictionary = BlessingRegistry.get_data(str(id))
		var label_text: String = "%s %s" % [
			str(data.get("symbol", "?")),
			str(data.get("title", id)),
		]
		if count > 1:
			label_text += " x%d" % count
		parts.append(label_text)

	if parts.is_empty():
		blessing_label.text = "Bendiciones: ninguna"
	else:
		blessing_label.text = "Bendiciones: " + " · ".join(PackedStringArray(parts))


func _advance_zone() -> void:
	# Congela el timer mientras se muestra la transición.
	_transitioning = true
	_show_zone_banner("ZONA %d COMPLETADA" % (_zone_index + 1))
	await get_tree().create_timer(zone_banner_hold, false).timeout

	if not GameState.is_run_active:
		_transitioning = false
		return

	_zone_index += 1
	_load_zone(_zone_index)
	_show_zone_banner("ZONA %d" % (_zone_index + 1))
	await get_tree().create_timer(zone_banner_hold, false).timeout
	_transitioning = false


func _load_zone(index: int) -> void:
	if index < 0 or index >= ZONE_SCENES.size():
		return

	var scene: PackedScene = ZONE_SCENES[index]
	var new_zone: Node3D = scene.instantiate() as Node3D
	zones_root.add_child(new_zone)

	if _current_zone != null and is_instance_valid(_current_zone):
		_current_zone.queue_free()
	_current_zone = new_zone

	zone_label.text = "Zona %d" % (index + 1)


func _show_zone_banner(text: String) -> void:
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()

	zone_banner.text = text
	zone_banner.modulate.a = 0.0
	zone_banner.show()

	_banner_tween = create_tween()
	_banner_tween.tween_property(zone_banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_interval(zone_banner_hold * 0.5)
	_banner_tween.tween_property(zone_banner, "modulate:a", 0.0, 0.3)
	_banner_tween.tween_callback(Callable(zone_banner, "hide"))


func _hide_zone_banner() -> void:
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = null
	zone_banner.hide()


func _on_damage_number_requested(world_position: Vector3, amount: float) -> void:
	var number: Node3D = DAMAGE_NUMBER_SCENE.instantiate() as Node3D
	add_child(number)
	number.call("show_damage", world_position, amount)


func _on_settings_changed() -> void:
	minimap.visible = Settings.show_minimap


func _on_boss_spawned(_boss: Node, max_health: float) -> void:
	boss_bar.max_value = max_health
	boss_bar.value = max_health
	boss_hp_label.text = "%d / %d" % [int(max_health), int(max_health)]
	boss_label.show()
	boss_bar.show()
	boss_hp_label.show()
	boss_panel.show()


func _on_boss_health_changed(current_health: float, max_health: float) -> void:
	boss_bar.max_value = max_health
	boss_bar.value = current_health
	boss_hp_label.text = "%d / %d" % [int(current_health), int(max_health)]


func _on_boss_defeated() -> void:
	_hide_boss_ui()


func _on_player_damaged(_amount: float) -> void:
	_update_health_label()


func _on_ammo_changed(current: int, maximum: int) -> void:
	ammo_label.text = "%d / %d" % [current, maximum]
	ammo_bar.max_value = maximum
	ammo_bar.value = current


func _on_weapon_changed(weapon_name: String) -> void:
	weapon_label.text = weapon_name
	_update_weapon_slots()


func _update_weapon_slots() -> void:
	var current_weapon: WeaponData = player.get("weapon_data") as WeaponData
	var current_name: String = current_weapon.weapon_name if current_weapon != null else ""
	var parts: Array[String] = []
	var ids: Array = GameState.owned_weapons
	for index in mini(ids.size(), 3):
		var data: WeaponData = WeaponRegistry.get_data(str(ids[index]))
		if data == null:
			continue
		if data.weapon_name == current_name:
			parts.append(
				"[color=#f2c040][b]%d %s[/b][/color]" % [index + 1, data.weapon_name]
			)
		else:
			parts.append("%d %s" % [index + 1, data.weapon_name])
	weapon_slots.text = "  ·  ".join(PackedStringArray(parts))


func _on_style_changed(rank: String, rank_index: int, progress: float, combo: int) -> void:
	style_label.text = "%s · x%d" % [rank, combo]
	style_label.add_theme_color_override("font_color", _style_color(rank_index))
	style_bar.value = progress


func _on_critical_hit(world_position: Vector3, _damage: float) -> void:
	var sparks: Node3D = SPARK_BURST_SCENE.instantiate() as Node3D
	add_child(sparks)
	sparks.call("start", world_position, true)


func _style_color(rank_index: int) -> Color:
	match rank_index:
		0:
			return Color(0.72, 0.78, 0.88, 1)
		1:
			return Color(0.4, 0.75, 1.0, 1)
		2:
			return Color(0.3, 0.9, 0.85, 1)
		3:
			return Color(0.4, 0.95, 0.55, 1)
		4:
			return Color(0.95, 0.8, 0.25, 1)
		5:
			return Color(1.0, 0.55, 0.2, 1)
		6:
			return Color(1.0, 0.3, 0.25, 1)
		_:
			return Color(1.0, 0.4, 0.9, 1)


func _on_player_died() -> void:
	Diagnostics.mark("player_died", {"health": float(player.get("current_health"))})
	GameState.end_run("death")


func _on_run_ended(reason: String) -> void:
	# Congela la run y muestra el resumen. La pausa deja de responder.
	# El cursor se libera antes de pausar para que el menú sea clickeable ya.
	Diagnostics.mark("run_ended_ui", {"reason": reason, "paused": get_tree().paused})
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	pause_menu.call("set_enabled", false)
	_hide_boss_ui()
	_hide_zone_banner()
	game_over_menu.call("show_result", reason, GameState.money)


func _hide_boss_ui() -> void:
	boss_label.hide()
	boss_bar.hide()
	boss_hp_label.hide()
	boss_panel.hide()


func _update_money_label(amount: int) -> void:
	money_label.text = "$%d" % amount


func _update_health_label() -> void:
	var current: float = float(player.get("current_health"))
	var maximum: float = float(player.get("max_health"))
	health_label.text = "HP %d/%d" % [int(current), int(maximum)]
