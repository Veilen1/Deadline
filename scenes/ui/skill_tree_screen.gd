extends Control

const HUB_SCENE: String = "res://scenes/ui/hub.tscn"
const MAP_SIZE: Vector2 = Vector2(1000.0, 520.0)
const NODE_SIZE: Vector2 = Vector2(54.0, 54.0)
const TOOLTIP_SIZE: Vector2 = Vector2(300.0, 180.0)

@onready var map: Control = $Margin/VBox/MapScroll/Map
@onready var money_label: Label = $Margin/VBox/TopBar/MoneyLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var status_label: Label = $Margin/VBox/StatusLabel
@onready var tooltip: PanelContainer = $Margin/VBox/MapScroll/Map/Tooltip
@onready var tooltip_title: Label = $Margin/VBox/MapScroll/Map/Tooltip/Margin/VBox/TooltipTitle
@onready var tooltip_description: Label = $Margin/VBox/MapScroll/Map/Tooltip/Margin/VBox/TooltipDescription
@onready var tooltip_effects: Label = $Margin/VBox/MapScroll/Map/Tooltip/Margin/VBox/TooltipEffects
@onready var tooltip_pips: Control = $Margin/VBox/MapScroll/Map/Tooltip/Margin/VBox/LevelPips
@onready var tooltip_state: Label = $Margin/VBox/MapScroll/Map/Tooltip/Margin/VBox/TooltipState

var _node_buttons: Dictionary = {}
var _selected_id: String = SkillTree.ROOT_ID
var _hide_timer: Timer


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = 0.08
	_hide_timer.timeout.connect(_hide_tooltip)
	add_child(_hide_timer)

	_build_nodes()
	_bring_tooltip_front()
	tooltip.hide()

	GameState.money_changed.connect(_on_money_changed)
	back_button.pressed.connect(_on_back_pressed)
	_refresh()


func _build_nodes() -> void:
	for id in SkillTree.NODES:
		var skill_id: String = str(id)

		var button := Button.new()
		button.custom_minimum_size = NODE_SIZE
		button.size = NODE_SIZE
		button.position = _node_position(skill_id)
		button.add_theme_font_size_override("font_size", 16)
		button.mouse_entered.connect(_on_node_hovered.bind(skill_id))
		button.mouse_exited.connect(_on_node_exited)
		button.focus_entered.connect(_on_node_hovered.bind(skill_id))
		button.pressed.connect(_on_node_pressed.bind(skill_id))
		map.add_child(button)
		_node_buttons[skill_id] = button


func _node_position(skill_id: String) -> Vector2:
	var data: Dictionary = SkillTree.get_node_data(skill_id)
	var position: Vector2 = data.get("position", Vector2(0.5, 0.5))
	return position * MAP_SIZE - NODE_SIZE * 0.5


func _refresh() -> void:
	for id in _node_buttons:
		var skill_id: String = str(id)
		var button: Button = _node_buttons[skill_id] as Button
		var data: Dictionary = SkillTree.get_node_data(skill_id)
		var level: int = GameState.get_skill_level(skill_id)
		var max_level: int = int(data.get("max_level", 1))
		var symbol: String = str(data.get("symbol", "?"))

		button.text = "%s\n%d" % [symbol, level]

		if level > 0:
			button.add_theme_color_override(
				"font_color",
				Color(1.0, 0.9, 0.65) if level >= max_level else Color(0.98, 0.8, 0.3)
			)
			button.modulate = Color(1, 1, 1, 1)
		elif GameState.is_skill_available(skill_id):
			button.add_theme_color_override("font_color", Color(0.35, 0.9, 0.85, 1))
			button.modulate = Color(1, 1, 1, 1)
		else:
			button.add_theme_color_override("font_color", Color(0.42, 0.48, 0.58, 1))
			button.modulate = Color(0.72, 0.72, 0.78, 1)

	money_label.text = "$%d" % GameState.money
	map.queue_redraw()

	if tooltip.visible:
		_update_tooltip()


func _on_node_hovered(skill_id: String) -> void:
	_hide_timer.stop()
	_selected_id = skill_id
	_update_tooltip()
	_position_tooltip(skill_id)

	if not tooltip.visible:
		tooltip.modulate.a = 0.0
		tooltip.show()
		var tween: Tween = create_tween()
		tween.tween_property(tooltip, "modulate:a", 1.0, 0.12)


func _on_node_exited() -> void:
	_hide_timer.start()


func _hide_tooltip() -> void:
	tooltip.hide()


func _on_node_pressed(skill_id: String) -> void:
	_selected_id = skill_id
	var data: Dictionary = SkillTree.get_node_data(skill_id)
	var title: String = str(data.get("title", ""))
	var previous_level: int = GameState.get_skill_level(skill_id)
	var cost: int = GameState.skill_cost(skill_id)

	if previous_level >= int(data.get("max_level", 1)):
		status_label.text = "%s ya está al máximo." % title
	elif not GameState.is_skill_available(skill_id):
		status_label.text = "Bloqueado: mejorá un nodo adyacente."
	elif GameState.money < cost:
		status_label.text = "Te faltan $%d para %s." % [cost - GameState.money, title]
	elif GameState.upgrade_skill(skill_id):
		AudioDirector.play_upgrade()
		_refresh()
		status_label.text = (
			"Desbloqueado: %s" % title
			if previous_level == 0
			else "Mejorado: %s (nivel %d)" % [title, GameState.get_skill_level(skill_id)]
		)
	else:
		status_label.text = "No se pudo mejorar %s." % title

	_update_tooltip()
	_position_tooltip(skill_id)


func _update_tooltip() -> void:
	var data: Dictionary = SkillTree.get_node_data(_selected_id)
	if data.is_empty():
		return

	var level: int = GameState.get_skill_level(_selected_id)
	var max_level: int = int(data.get("max_level", 1))
	var cost: int = GameState.skill_cost(_selected_id)

	tooltip_title.text = str(data.get("title", ""))
	tooltip_description.text = str(data.get("description", ""))
	tooltip_effects.text = "Por nivel: " + _effects_text(data.get("effects", {}))
	tooltip_pips.call("set_levels", level, max_level)

	if level >= max_level:
		tooltip_state.text = "Nivel %d/%d · MÁXIMO" % [level, max_level]
	elif not GameState.is_skill_available(_selected_id):
		tooltip_state.text = "Nivel %d/%d · Bloqueado: mejorá un nodo adyacente" % [level, max_level]
	elif GameState.money < cost:
		tooltip_state.text = "Nivel %d/%d · Costo $%d · faltan $%d" % [
			level, max_level, cost, cost - GameState.money
		]
	else:
		tooltip_state.text = "Nivel %d/%d · Costo $%d · click para subir" % [level, max_level, cost]


func _position_tooltip(skill_id: String) -> void:
	var button: Button = _node_buttons.get(skill_id) as Button
	if button == null:
		return

	var position: Vector2 = button.position + Vector2(NODE_SIZE.x + 8.0, 0.0)
	if position.x + TOOLTIP_SIZE.x > MAP_SIZE.x:
		position.x = button.position.x - TOOLTIP_SIZE.x - 8.0
	position.y = clampf(button.position.y - 40.0, 0.0, MAP_SIZE.y - TOOLTIP_SIZE.y)
	tooltip.position = position
	_bring_tooltip_front()


func _bring_tooltip_front() -> void:
	map.move_child(tooltip, map.get_child_count() - 1)


func _effects_text(effects: Dictionary) -> String:
	var parts: Array[String] = []
	if effects.has("damage_bonus"):
		parts.append("+%d daño" % int(round(float(effects["damage_bonus"]))))
	if effects.has("health_bonus"):
		parts.append("+%d vida" % int(round(float(effects["health_bonus"]))))
	if effects.has("time_bonus"):
		parts.append("+%d s de timer" % int(round(float(effects["time_bonus"]))))
	if effects.has("ammo_capacity_bonus"):
		parts.append("+%d balas" % int(round(float(effects["ammo_capacity_bonus"]))))
	if effects.has("ammo_regen_bonus"):
		parts.append("+%.1f balas/s" % float(effects["ammo_regen_bonus"]))
	if effects.has("fire_rate_bonus"):
		parts.append("+%d%% cadencia" % int(round(float(effects["fire_rate_bonus"]) * 100.0)))
	if effects.has("crit_bonus"):
		parts.append("+%d%% daño crítico" % int(round(float(effects["crit_bonus"]) * 100.0)))
	if effects.has("crit_refund"):
		parts.append("+1 bala por crítico")
	if effects.has("damage_reduction"):
		parts.append("-%d%% daño recibido" % int(round(float(effects["damage_reduction"]) * 100.0)))

	if parts.is_empty():
		return "Sin bonus."
	return " · ".join(PackedStringArray(parts))


func _on_money_changed(_new_amount: int) -> void:
	_refresh()


func _on_back_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(HUB_SCENE)
