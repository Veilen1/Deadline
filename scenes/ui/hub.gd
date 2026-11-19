extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const GAME_SCENE: String = "res://scenes/main.tscn"

@export_group("Time Upgrade")
@export var upgrade_time_cost: int = 50
@export var upgrade_time_cost_step: int = 25
@export var upgrade_time_bonus: float = 10.0

@export_group("Damage Upgrade")
@export var upgrade_damage_cost: int = 60
@export var upgrade_damage_cost_step: int = 30
@export var upgrade_damage_bonus: float = 5.0

@export_group("Health Upgrade")
@export var upgrade_health_cost: int = 70
@export var upgrade_health_cost_step: int = 35
@export var upgrade_health_bonus: float = 20.0

@onready var money_label: Label = $CenterContainer/Menu/MoneyLabel
@onready var timer_label: Label = $CenterContainer/Menu/TimerLabel
@onready var bonus_label: Label = $CenterContainer/Menu/BonusLabel
@onready var buy_time_button: Button = $CenterContainer/Menu/BuyTimeButton
@onready var buy_damage_button: Button = $CenterContainer/Menu/BuyDamageButton
@onready var buy_health_button: Button = $CenterContainer/Menu/BuyHealthButton
@onready var play_button: Button = $CenterContainer/Menu/PlayButton
@onready var main_menu_button: Button = $CenterContainer/Menu/MainMenuButton
@onready var reset_button: Button = $CenterContainer/Menu/ResetButton
@onready var reset_dialog: ConfirmationDialog = $ResetDialog


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.money_changed.connect(_on_money_changed)
	buy_time_button.pressed.connect(_on_buy_time_pressed)
	buy_damage_button.pressed.connect(_on_buy_damage_pressed)
	buy_health_button.pressed.connect(_on_buy_health_pressed)
	play_button.pressed.connect(_on_play_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	reset_dialog.confirmed.connect(_on_reset_confirmed)
	_update_ui()
	if buy_time_button.disabled:
		play_button.grab_focus()
	else:
		buy_time_button.grab_focus()


func _on_buy_time_pressed() -> void:
	var cost: int = _upgrade_cost(upgrade_time_cost, upgrade_time_cost_step, "time")
	if not GameState.spend_money(cost):
		return

	GameState.add_run_time(upgrade_time_bonus)
	GameState.register_upgrade("time", upgrade_time_bonus)
	_update_ui()


func _on_buy_damage_pressed() -> void:
	var cost: int = _upgrade_cost(upgrade_damage_cost, upgrade_damage_cost_step, "damage")
	if not GameState.spend_money(cost):
		return

	GameState.register_upgrade("damage", upgrade_damage_bonus)
	_update_ui()


func _on_buy_health_pressed() -> void:
	var cost: int = _upgrade_cost(upgrade_health_cost, upgrade_health_cost_step, "health")
	if not GameState.spend_money(cost):
		return

	GameState.register_upgrade("health", upgrade_health_bonus)
	_update_ui()


func _on_money_changed(_new_amount: int) -> void:
	_update_ui()


func _on_play_pressed() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_main_menu_pressed() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_reset_pressed() -> void:
	reset_dialog.popup_centered(Vector2i(460, 150))


func _on_reset_confirmed() -> void:
	GameState.reset_progress()
	_update_ui()


func _update_ui() -> void:
	money_label.text = "$%d" % GameState.money
	timer_label.text = "Timer inicial: %.0f s" % GameState.base_run_time

	var damage_bonus: float = float(GameState.upgrades.get("damage_bonus", 0.0))
	var health_bonus: float = float(GameState.upgrades.get("health_bonus", 0.0))
	bonus_label.text = "Bonos: +%d daño, +%d vida" % [int(round(damage_bonus)), int(round(health_bonus))]

	var time_cost: int = _upgrade_cost(upgrade_time_cost, upgrade_time_cost_step, "time")
	var damage_cost: int = _upgrade_cost(upgrade_damage_cost, upgrade_damage_cost_step, "damage")
	var health_cost: int = _upgrade_cost(upgrade_health_cost, upgrade_health_cost_step, "health")

	buy_time_button.text = "Timer +%ds (nivel %d) — $%d" % [
		int(round(upgrade_time_bonus)), GameState.get_upgrade_level("time"), time_cost
	]
	buy_damage_button.text = "Daño +%d (nivel %d) — $%d" % [
		int(round(upgrade_damage_bonus)), GameState.get_upgrade_level("damage"), damage_cost
	]
	buy_health_button.text = "Vida +%d (nivel %d) — $%d" % [
		int(round(upgrade_health_bonus)), GameState.get_upgrade_level("health"), health_cost
	]

	buy_time_button.disabled = GameState.money < time_cost
	buy_damage_button.disabled = GameState.money < damage_cost
	buy_health_button.disabled = GameState.money < health_cost


func _upgrade_cost(base_cost: int, cost_step: int, upgrade_id: String) -> int:
	return base_cost + cost_step * GameState.get_upgrade_level(upgrade_id)
