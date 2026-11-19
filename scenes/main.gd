extends Node3D

@onready var money_label: Label = $CanvasLayer/MoneyLabel
@onready var timer_label: Label = $CanvasLayer/TimerLabel


func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.timer_changed.connect(_on_timer_changed)
	EventBus.enemy_hit.connect(_on_enemy_hit)
	_update_money_label(GameState.money)
	GameState.start_run()


func _process(delta: float) -> void:
	GameState.tick_run(delta)

	# TODO: Fase 2 — escuchar GameState.run_ended para volver al hub
	# (timer en 0, muerte o zona completada).


func _on_money_changed(new_amount: int) -> void:
	_update_money_label(new_amount)


func _on_enemy_hit(_enemy: Node, _hit_zone: String, _damage: float, money_value: int) -> void:
	GameState.add_money(money_value)


func _on_timer_changed(remaining: float) -> void:
	timer_label.text = "%.1f s" % remaining


func _update_money_label(amount: int) -> void:
	money_label.text = "$%d" % amount
