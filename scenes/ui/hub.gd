extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const GAME_SCENE: String = "res://scenes/main.tscn"

@export var upgrade_time_cost: int = 50
@export var upgrade_time_bonus: float = 10.0

@onready var money_label: Label = $CenterContainer/Menu/MoneyLabel
@onready var timer_label: Label = $CenterContainer/Menu/TimerLabel
@onready var buy_time_button: Button = $CenterContainer/Menu/BuyTimeButton
@onready var play_button: Button = $CenterContainer/Menu/PlayButton
@onready var main_menu_button: Button = $CenterContainer/Menu/MainMenuButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.money_changed.connect(_on_money_changed)
	buy_time_button.pressed.connect(_on_buy_time_pressed)
	play_button.pressed.connect(_on_play_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	_update_money_label(GameState.money)
	_update_timer_label()
	buy_time_button.grab_focus()


func _on_buy_time_pressed() -> void:
	# El costo se valida en GameState; si no alcanza, no hay cambios.
	if not GameState.spend_money(upgrade_time_cost):
		return

	GameState.add_run_time(upgrade_time_bonus)
	_update_timer_label()


func _on_money_changed(new_amount: int) -> void:
	_update_money_label(new_amount)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _update_money_label(amount: int) -> void:
	money_label.text = "$%d" % amount
	buy_time_button.disabled = amount < upgrade_time_cost


func _update_timer_label() -> void:
	timer_label.text = "Timer inicial: %.0f s" % GameState.base_run_time
