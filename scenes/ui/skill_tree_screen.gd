extends Control

const HUB_SCENE: String = "res://scenes/ui/hub.tscn"
const MAP_SIZE: Vector2 = Vector2(1000.0, 380.0)
const NODE_SIZE: Vector2 = Vector2(150.0, 54.0)

@onready var map: Control = $Margin/VBox/MapScroll/Map
@onready var money_label: Label = $Margin/VBox/TopBar/MoneyLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var selected_title: Label = $Margin/VBox/Details/Margin/VBox/SelectedTitle
@onready var selected_description: Label = $Margin/VBox/Details/Margin/VBox/SelectedDescription
@onready var selected_effects: Label = $Margin/VBox/Details/Margin/VBox/SelectedEffects
@onready var selected_cost: Label = $Margin/VBox/Details/Margin/VBox/BottomRow/SelectedCost
@onready var unlock_button: Button = $Margin/VBox/Details/Margin/VBox/BottomRow/UnlockButton
@onready var status_label: Label = $Margin/VBox/Details/Margin/VBox/StatusLabel

var _node_buttons: Dictionary = {}
var _selected_id: String = SkillTree.ROOT_ID


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_nodes()
	GameState.money_changed.connect(_on_money_changed)
	unlock_button.pressed.connect(_on_unlock_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_select(SkillTree.ROOT_ID)


func _build_nodes() -> void:
	for id in SkillTree.NODES:
		var skill_id: String = str(id)
		var data: Dictionary = SkillTree.get_node_data(skill_id)

		var button := Button.new()
		button.custom_minimum_size = NODE_SIZE
		button.size = NODE_SIZE
		button.position = _node_position(skill_id)
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_on_node_pressed.bind(skill_id))
		map.add_child(button)
		_node_buttons[skill_id] = button

	_refresh()


func _node_position(skill_id: String) -> Vector2:
	var data: Dictionary = SkillTree.get_node_data(skill_id)
	var position: Vector2 = data.get("position", Vector2(0.5, 0.5))
	return position * MAP_SIZE - NODE_SIZE * 0.5


func _refresh() -> void:
	for id in _node_buttons:
		var skill_id: String = str(id)
		var button: Button = _node_buttons[skill_id] as Button
		var data: Dictionary = SkillTree.get_node_data(skill_id)
		var title: String = str(data.get("title", ""))

		if GameState.is_skill_unlocked(skill_id):
			button.disabled = false
			button.text = "✓ " + title
			button.add_theme_color_override("font_color", Color(0.98, 0.82, 0.35))
			button.modulate = Color(1, 1, 1, 1)
		elif GameState.is_skill_available(skill_id):
			button.disabled = false
			button.text = "%s\n$%d" % [title, int(data.get("cost", 0))]
			button.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
			button.modulate = Color(1, 1, 1, 1)
		else:
			button.disabled = true
			button.text = title + "\nBloqueado"
			button.add_theme_color_override("font_disabled_color", Color(0.42, 0.48, 0.58))
			button.modulate = Color(0.8, 0.8, 0.85, 1)

	money_label.text = "$%d" % GameState.money
	map.queue_redraw()
	_update_details()


func _select(skill_id: String) -> void:
	_selected_id = skill_id
	status_label.text = ""
	_update_details()


func _update_details() -> void:
	var data: Dictionary = SkillTree.get_node_data(_selected_id)
	if data.is_empty():
		return

	selected_title.text = str(data.get("title", ""))
	selected_description.text = str(data.get("description", ""))
	selected_effects.text = _effects_text(data.get("effects", {}))

	var cost: int = int(data.get("cost", 0))
	if GameState.is_skill_unlocked(_selected_id):
		selected_cost.text = "Desbloqueado"
		unlock_button.disabled = true
		unlock_button.text = "Desbloqueado"
	elif not GameState.is_skill_available(_selected_id):
		selected_cost.text = "Bloqueado: necesitás un nodo adyacente"
		unlock_button.disabled = true
		unlock_button.text = "Bloqueado"
	elif GameState.money < cost:
		selected_cost.text = "Costo: $%d · te faltan $%d" % [cost, cost - GameState.money]
		unlock_button.disabled = true
		unlock_button.text = "Sin plata"
	else:
		selected_cost.text = "Costo: $%d" % cost
		unlock_button.disabled = false
		unlock_button.text = "Desbloquear"


func _effects_text(effects: Dictionary) -> String:
	var parts: Array[String] = []
	if effects.has("damage_bonus"):
		parts.append("+%d daño" % int(round(float(effects["damage_bonus"]))))
	if effects.has("health_bonus"):
		parts.append("+%d vida" % int(round(float(effects["health_bonus"]))))
	if effects.has("time_bonus"):
		parts.append("+%d s de timer" % int(round(float(effects["time_bonus"]))))
	if effects.has("ammo_capacity_bonus"):
		parts.append("+%d balas/cargador" % int(round(float(effects["ammo_capacity_bonus"]))))
	if effects.has("ammo_regen_bonus"):
		parts.append("+%.1f balas/s" % float(effects["ammo_regen_bonus"]))
	if effects.has("fire_rate_bonus"):
		parts.append("+%d%% cadencia" % int(round(float(effects["fire_rate_bonus"]) * 100.0)))

	if parts.is_empty():
		return "Sin bonus pasivo."
	return " · ".join(PackedStringArray(parts))


func _on_node_pressed(skill_id: String) -> void:
	_select(skill_id)


func _on_unlock_pressed() -> void:
	var data: Dictionary = SkillTree.get_node_data(_selected_id)
	var title: String = str(data.get("title", ""))
	if GameState.unlock_skill(_selected_id):
		_refresh()
		status_label.text = "Desbloqueado: %s" % title
	else:
		_update_details()
		status_label.text = "No se pudo desbloquear."


func _on_money_changed(_new_amount: int) -> void:
	_refresh()


func _on_back_pressed() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(HUB_SCENE)
