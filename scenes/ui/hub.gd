extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const CONTRACTS_SCENE: String = "res://scenes/ui/contracts.tscn"
const SKILL_TREE_SCENE: String = "res://scenes/ui/skill_tree.tscn"
const SHOP_SCENE: String = "res://scenes/ui/shop.tscn"
const CHALLENGES_SCENE: String = "res://scenes/ui/challenges.tscn"

@onready var money_label: Label = $Margin/VBox/TopBar/Resources/MoneyCard/VBox/MoneyLabel
@onready var cores_label: Label = $Margin/VBox/TopBar/Resources/CoresCard/VBox/CoresLabel
@onready var timer_label: Label = $Margin/VBox/Content/PlayCard/VBox/TimerLabel
@onready var bonus_label: Label = $Margin/VBox/Content/PlayCard/VBox/BonusLabel
@onready var contract_label: Label = $Margin/VBox/Content/PlayCard/VBox/ContractLabel
@onready var cycle_label: Label = $Margin/VBox/Content/PlayCard/VBox/CycleLabel
@onready var cycle_down_button: Button = $Margin/VBox/Content/PlayCard/VBox/CycleRow/CycleDownButton
@onready var cycle_up_button: Button = $Margin/VBox/Content/PlayCard/VBox/CycleRow/CycleUpButton
@onready var skill_tree_button: Button = $Margin/VBox/Content/Side/ProgressCard/VBox/SkillTreeButton
@onready var shop_button: Button = $Margin/VBox/Content/Side/ArsenalCard/VBox/ShopButton
@onready var challenges_button: Button = $Margin/VBox/Content/Side/ChallengesCard/VBox/ChallengesButton
@onready var play_button: Button = $Margin/VBox/Content/PlayCard/VBox/PlayButton
@onready var main_menu_button: Button = $Margin/VBox/BottomBar/MainMenuButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.reset_mood()
	GameState.money_changed.connect(_on_money_changed)
	GameState.cores_changed.connect(_on_cores_changed)
	GameState.challenges_changed.connect(_update_ui)
	skill_tree_button.pressed.connect(_on_skill_tree_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	challenges_button.pressed.connect(_on_challenges_pressed)
	cycle_down_button.pressed.connect(_on_cycle_down_pressed)
	cycle_up_button.pressed.connect(_on_cycle_up_pressed)
	play_button.pressed.connect(_on_play_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	_update_ui()
	play_button.grab_focus()


func _on_money_changed(_new_amount: int) -> void:
	_update_ui()


func _on_cores_changed(_new_amount: int) -> void:
	_update_ui()


func _on_skill_tree_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(SKILL_TREE_SCENE)


func _on_shop_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(SHOP_SCENE)


func _on_challenges_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(CHALLENGES_SCENE)


func _on_play_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(CONTRACTS_SCENE)


func _on_cycle_down_pressed() -> void:
	if GameState.cycle <= 1:
		Toast.show_toast(
			"DIFICULTAD",
			"Dificultad mínima",
			"Ya estás en el nivel base, sin modificadores enemigos.",
			"",
			Color(0.3, 0.85, 0.8, 1)
		)
		return
	if GameState.decrease_cycle():
		AudioDirector.play_upgrade()
		_update_ui()
		_show_cycle_toast()


func _on_cycle_up_pressed() -> void:
	if GameState.runs_completed < 1:
		Toast.show_toast(
			"DIFICULTAD BLOQUEADA",
			"Completá una run",
			"Terminá una run para desbloquear el ajuste de dificultad.",
			"Después podés subir o bajar el nivel cuando quieras.",
			Color(0.95, 0.75, 0.25, 1)
		)
		return
	if GameState.cycle >= 10:
		Toast.show_toast(
			"DIFICULTAD",
			"Dificultad máxima",
			"Ya estás en el nivel 10.",
			"",
			Color(0.95, 0.75, 0.25, 1)
		)
		return
	if GameState.increase_cycle():
		AudioDirector.play_upgrade()
		_update_ui()
		_show_cycle_toast()


func _show_cycle_toast() -> void:
	Toast.show_toast(
		"DIFICULTAD AJUSTADA",
		"Dificultad %d" % GameState.cycle,
		_cycle_summary(),
		"Núcleos al completar la run: ×%.2f · se aplica a la próxima run." % GameState.cycle_core_mult(),
		Color(0.95, 0.75, 0.25, 1)
	)


func _cycle_summary() -> String:
	if GameState.cycle <= 1:
		return "Sin modificadores enemigos."
	var health: int = int(round((GameState.cycle_enemy_health_mult() - 1.0) * 100.0))
	var damage: int = int(round((GameState.cycle_enemy_damage_mult() - 1.0) * 100.0))
	var speed: int = int(round((GameState.cycle_enemy_speed_mult() - 1.0) * 100.0))
	return "Enemigos +%d%% vida, +%d%% daño, +%d%% velocidad." % [health, damage, speed]


func _on_main_menu_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(MAIN_MENU_SCENE)


func _update_ui() -> void:
	money_label.text = "$%d" % GameState.money
	cores_label.text = "◈ %d núcleos" % GameState.cores
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

	var contract: Dictionary = GameState.contract_data()
	if contract.is_empty():
		contract_label.text = "Contrato: sin contrato"
	else:
		contract_label.text = "Contrato: %s (+%d núcleos)" % [
			str(contract.get("title", "")),
			int(contract.get("core_bonus", 0)),
		]

	cycle_label.text = "Dificultad %d · grado máximo %s" % [GameState.cycle, GameState.best_grade]
	cycle_label.tooltip_text = _cycle_summary() + "\nNúcleos al completar: ×%.2f" % GameState.cycle_core_mult()
	cycle_down_button.disabled = GameState.cycle <= 1
	cycle_up_button.disabled = GameState.cycle >= 10
