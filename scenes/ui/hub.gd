extends Control

@export var upgrade_time_cost: int = 50
@export var upgrade_time_bonus: float = 10.0

@onready var money_label: Label = $CenterContainer/Menu/MoneyLabel
@onready var buy_time_button: Button = $CenterContainer/Menu/BuyTimeButton
@onready var play_button: Button = $CenterContainer/Menu/PlayButton


func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	buy_time_button.pressed.connect(_on_buy_time_pressed)
	play_button.pressed.connect(_on_play_pressed)
	_update_money_label(GameState.money)


func _on_buy_time_pressed() -> void:
	if not GameState.spend_money(upgrade_time_cost):
		return

	GameState.base_run_time += upgrade_time_bonus
	# TODO: Fase 2.2 — registrar la mejora en GameState.upgrades para persistirla/serializarla.
	_update_money_label(GameState.money)


func _on_money_changed(new_amount: int) -> void:
	_update_money_label(new_amount)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _update_money_label(amount: int) -> void:
	money_label.text = "$%d" % amount
