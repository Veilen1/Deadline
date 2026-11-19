extends Node3D

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/effects/damage_number.tscn")

@onready var player: Node = $Player
@onready var money_label: Label = $CanvasLayer/MoneyLabel
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var health_label: Label = $CanvasLayer/HealthLabel
@onready var boss_label: Label = $CanvasLayer/BossLabel
@onready var boss_bar: ProgressBar = $CanvasLayer/BossBar
@onready var boss_hp_label: Label = $CanvasLayer/BossHpLabel
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var game_over_menu: Control = $CanvasLayer/GameOverMenu


func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.timer_changed.connect(_on_timer_changed)
	GameState.run_ended.connect(_on_run_ended)
	EventBus.enemy_hit.connect(_on_enemy_hit)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.damage_number_requested.connect(_on_damage_number_requested)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	_update_money_label(GameState.money)
	_update_health_label()
	GameState.start_run()


func _process(delta: float) -> void:
	GameState.tick_run(delta)


func _on_money_changed(new_amount: int) -> void:
	_update_money_label(new_amount)


func _on_enemy_hit(_enemy: Node, _hit_zone: String, _damage: float, money_value: int) -> void:
	GameState.add_money(money_value)


func _on_timer_changed(remaining: float) -> void:
	timer_label.text = "%.1f s" % remaining


func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Oleada %d" % wave_number


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
