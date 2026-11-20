extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const GAME_SCENE: String = "res://scenes/main.tscn"
const SKILL_TREE_SCENE: String = "res://scenes/ui/skill_tree.tscn"
const SHOP_SCENE: String = "res://scenes/ui/shop.tscn"

@onready var money_label: Label = $CenterContainer/Menu/MoneyLabel
@onready var timer_label: Label = $CenterContainer/Menu/TimerLabel
@onready var bonus_label: Label = $CenterContainer/Menu/BonusLabel
@onready var skill_tree_button: Button = $CenterContainer/Menu/SkillTreeButton
@onready var shop_button: Button = $CenterContainer/Menu/ShopButton
@onready var play_button: Button = $CenterContainer/Menu/PlayButton
@onready var main_menu_button: Button = $CenterContainer/Menu/MainMenuButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.money_changed.connect(_on_money_changed)
	skill_tree_button.pressed.connect(_on_skill_tree_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	play_button.pressed.connect(_on_play_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	_update_ui()
	skill_tree_button.grab_focus()


func _on_money_changed(_new_amount: int) -> void:
	_update_ui()


func _on_skill_tree_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(SKILL_TREE_SCENE)


func _on_shop_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(SHOP_SCENE)


func _on_play_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(GAME_SCENE)


func _on_main_menu_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(MAIN_MENU_SCENE)


func _update_ui() -> void:
	money_label.text = "$%d" % GameState.money
	timer_label.text = "Timer inicial: %.0f s" % GameState.base_run_time

	var damage_bonus: float = (
		float(GameState.upgrades.get("damage_bonus", 0.0))
		+ float(GameState.skill_bonuses.get("damage_bonus", 0.0))
	)
	var health_bonus: float = (
		float(GameState.upgrades.get("health_bonus", 0.0))
		+ float(GameState.skill_bonuses.get("health_bonus", 0.0))
	)
	bonus_label.text = "Bonos: +%d daño, +%d vida · %d nodos" % [
		int(round(damage_bonus)),
		int(round(health_bonus)),
		GameState.get_unlocked_skill_count(),
	]
