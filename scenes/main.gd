extends Node3D

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/effects/damage_number.tscn")
const ZONE_SCENES = [
	preload("res://scenes/levels/zone_01.tscn"),
	preload("res://scenes/levels/zone_02.tscn"),
]

@export var zone_banner_hold: float = 1.2

@onready var player: Node = $Player
@onready var zones_root: Node3D = $Zones
@onready var money_label: Label = $CanvasLayer/MoneyLabel
@onready var zone_label: Label = $CanvasLayer/ZoneLabel
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var health_label: Label = $CanvasLayer/HealthLabel
@onready var boss_label: Label = $CanvasLayer/BossLabel
@onready var boss_bar: ProgressBar = $CanvasLayer/BossBar
@onready var boss_hp_label: Label = $CanvasLayer/BossHpLabel
@onready var zone_banner: Label = $CanvasLayer/ZoneBanner
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var game_over_menu: Control = $CanvasLayer/GameOverMenu

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
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.zone_completed.connect(_on_zone_completed)
	EventBus.damage_number_requested.connect(_on_damage_number_requested)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	player.call("apply_meta_upgrades", GameState.upgrades)
	_update_money_label(GameState.money)
	_update_health_label()
	_load_zone(_zone_index)
	GameState.start_run()


func _process(delta: float) -> void:
	if not _transitioning:
		GameState.tick_run(delta)


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

	if _zone_index + 1 >= ZONE_SCENES.size():
		GameState.end_run("completed")
		return

	_advance_zone()


func _advance_zone() -> void:
	# Congela el timer mientras se muestra la transición.
	_transitioning = true
	_show_zone_banner("ZONA %d COMPLETADA" % (_zone_index + 1))
	await get_tree().create_timer(zone_banner_hold).timeout

	if not GameState.is_run_active:
		_transitioning = false
		return

	_zone_index += 1
	_load_zone(_zone_index)
	_show_zone_banner("ZONA %d" % (_zone_index + 1))
	await get_tree().create_timer(zone_banner_hold).timeout
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


func _on_boss_spawned(_boss: Node, max_health: float) -> void:
	boss_bar.max_value = max_health
	boss_bar.value = max_health
	boss_hp_label.text = "%d / %d" % [int(max_health), int(max_health)]
	boss_label.show()
	boss_bar.show()
	boss_hp_label.show()


func _on_boss_health_changed(current_health: float, max_health: float) -> void:
	boss_bar.max_value = max_health
	boss_bar.value = current_health
	boss_hp_label.text = "%d / %d" % [int(current_health), int(max_health)]


func _on_boss_defeated() -> void:
	_hide_boss_ui()


func _on_player_damaged(_amount: float) -> void:
	_update_health_label()


func _on_player_died() -> void:
	GameState.end_run("death")


func _on_run_ended(reason: String) -> void:
	# Congela la run y muestra el resumen. La pausa deja de responder.
	get_tree().paused = true
	pause_menu.call("set_enabled", false)
	_hide_boss_ui()
	_hide_zone_banner()
	game_over_menu.call("show_result", reason, GameState.money)


func _hide_boss_ui() -> void:
	boss_label.hide()
	boss_bar.hide()
	boss_hp_label.hide()


func _update_money_label(amount: int) -> void:
	money_label.text = "$%d" % amount


func _update_health_label() -> void:
	var current: float = float(player.get("current_health"))
	var maximum: float = float(player.get("max_health"))
	health_label.text = "HP %d/%d" % [int(current), int(maximum)]
