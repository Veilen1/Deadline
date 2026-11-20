extends Control

const HUB_SCENE: String = "res://scenes/ui/hub.tscn"
const GAME_SCENE: String = "res://scenes/main.tscn"

@onready var cores_label: Label = $Margin/VBox/TopBar/CoresLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var list: VBoxContainer = $Margin/VBox/Scroll/List
@onready var no_contract_button: Button = $Margin/VBox/Bottom/NoContractButton
@onready var start_button: Button = $Margin/VBox/Bottom/StartButton
@onready var status_label: Label = $Margin/VBox/StatusLabel

var _selected_id: String = "none"
var _choices: Array[String] = []
var _buttons: Dictionary = {}
var _group: ButtonGroup


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_group = ButtonGroup.new()
	_choices = ContractRegistry.random_ids(3)

	cores_label.text = "◈ %d núcleos" % GameState.cores
	_build_choices()
	back_button.pressed.connect(_on_back_pressed)
	no_contract_button.pressed.connect(_select.bind("none"))
	start_button.pressed.connect(_on_start_pressed)
	_select(GameState.selected_contract if _is_choice(GameState.selected_contract) else "none")
	start_button.grab_focus()


func _is_choice(contract_id: String) -> bool:
	return _choices.has(contract_id)


func _build_choices() -> void:
	for child in list.get_children():
		child.free()

	for contract_id in _choices:
		var data: Dictionary = ContractRegistry.get_data(contract_id)
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = _group
		button.custom_minimum_size = Vector2(0, 88)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		button.text = "%s\n%s\nRecompensa: +%d núcleos" % [
			str(data.get("title", contract_id)),
			str(data.get("description", "")),
			int(data.get("core_bonus", 0)),
		]
		button.pressed.connect(_select.bind(contract_id))
		list.add_child(button)
		_buttons[contract_id] = button

	no_contract_button.toggle_mode = true
	no_contract_button.button_group = _group


func _select(contract_id: String) -> void:
	_selected_id = contract_id
	if contract_id == "none":
		no_contract_button.button_pressed = true
		status_label.text = "Run estándar: sin modificadores ni bonus extra."
		return

	var selected_button: Button = _buttons.get(contract_id) as Button
	if selected_button != null:
		selected_button.button_pressed = true
	var data: Dictionary = ContractRegistry.get_data(contract_id)
	status_label.text = "Contrato activo: %s (+%d núcleos al completar)" % [
		str(data.get("title", contract_id)),
		int(data.get("core_bonus", 0)),
	]


func _on_start_pressed() -> void:
	GameState.selected_contract = _selected_id
	GameState.save_game()
	Transitions.change_scene_to_file(GAME_SCENE)


func _on_back_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(HUB_SCENE)
