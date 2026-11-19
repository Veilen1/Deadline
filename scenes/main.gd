extends Node3D

@onready var player: Node = $Player
@onready var money_label: Label = $CanvasLayer/MoneyLabel
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var health_label: Label = $CanvasLayer/HealthLabel
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


func _on_player_damaged(_amount: float) -> void:
	_update_health_label()


func _on_player_died() -> void:
	GameState.end_run("death")


func _on_run_ended(reason: String) -> void:
	# Congela la run y muestra el resumen. La pausa deja de responder.
	get_tree().paused = true
	pause_menu.call("set_enabled", false)
	game_over_menu.call("show_result", reason, GameState.money)


func _update_money_label(amount: int) -> void:
	money_label.text = "$%d" % amount


func _update_health_label() -> void:
	var current: float = float(player.get("current_health"))
	var maximum: float = float(player.get("max_health"))
	health_label.text = "HP %d/%d" % [int(current), int(maximum)]
