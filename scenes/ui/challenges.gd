extends Control

const HUB_SCENE: String = "res://scenes/ui/hub.tscn"

@onready var cores_label: Label = $Margin/VBox/TopBar/CoresLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var list: VBoxContainer = $Margin/VBox/Scroll/List
@onready var status_label: Label = $Margin/VBox/StatusLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.challenges_changed.connect(_rebuild)
	GameState.cores_changed.connect(_on_cores_changed)
	back_button.pressed.connect(_on_back_pressed)
	_rebuild()


func _on_cores_changed(_amount: int) -> void:
	_rebuild()


func _rebuild() -> void:
	cores_label.text = "◈ %d núcleos" % GameState.cores
	for child in list.get_children():
		child.free()
	for id in ChallengeRegistry.ids():
		_build_card(str(id))


func _build_card(challenge_id: String) -> void:
	var data: Dictionary = ChallengeRegistry.get_data(challenge_id)
	if data.is_empty():
		return

	var target: int = int(data.get("target", 1))
	var progress: int = GameState.get_challenge_progress(challenge_id)
	var completed: bool = GameState.is_challenge_completed(challenge_id)
	var claimed: bool = GameState.is_challenge_claimed(challenge_id)
	var reward_type: String = str(data.get("reward_type", ""))
	var reward_id: String = str(data.get("reward_id", ""))

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.1, 0.16, 1)
	style.border_color = Color(0.95, 0.75, 0.25, 1) if completed else Color(0.22, 0.32, 0.46, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	card.add_theme_stylebox_override("panel", style)
	list.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 5)
	row.add_child(info)

	var title := Label.new()
	title.text = str(data.get("title", challenge_id))
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25, 1))
	title.add_theme_font_size_override("font_size", 21)
	info.add_child(title)

	var description := Label.new()
	description.text = str(data.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color(0.7, 0.77, 0.87, 1))
	description.add_theme_font_size_override("font_size", 14)
	info.add_child(description)

	var bar := ProgressBar.new()
	bar.max_value = float(target)
	bar.value = float(progress)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	info.add_child(bar)

	var progress_label := Label.new()
	progress_label.text = "%d / %d" % [progress, target]
	progress_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.82, 1))
	progress_label.add_theme_font_size_override("font_size", 13)
	info.add_child(progress_label)

	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(190, 0)
	actions.add_theme_constant_override("separation", 8)
	row.add_child(actions)

	var reward := Label.new()
	reward.text = _reward_text(reward_type, reward_id)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward.add_theme_color_override("font_color", Color(0.3, 0.85, 0.8, 1))
	reward.add_theme_font_size_override("font_size", 14)
	actions.add_child(reward)

	if reward_type == "cores" and completed and not claimed:
		var claim_button := Button.new()
		claim_button.text = "Reclamar"
		claim_button.custom_minimum_size = Vector2(170, 36)
		claim_button.pressed.connect(_on_claim_pressed.bind(challenge_id))
		actions.add_child(claim_button)
	else:
		var state := Label.new()
		if reward_type == "weapon" and completed:
			state.text = "DESBLOQUEADA"
		elif claimed:
			state.text = "RECLAMADO"
		elif completed:
			state.text = "COMPLETADO"
		else:
			state.text = "EN CURSO"
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		state.add_theme_font_size_override("font_size", 14)
		state.add_theme_color_override(
			"font_color",
			Color(0.95, 0.75, 0.25, 1) if completed else Color(0.55, 0.62, 0.72, 1)
		)
		actions.add_child(state)


func _reward_text(reward_type: String, reward_id: String) -> String:
	if reward_type == "weapon":
		var weapon: WeaponData = WeaponRegistry.get_data(reward_id)
		return "Recompensa: %s" % (weapon.weapon_name if weapon != null else reward_id)
	if reward_type == "cores":
		return "Recompensa: ◈ %s" % reward_id
	return "Recompensa: ?"


func _on_claim_pressed(challenge_id: String) -> void:
	if GameState.claim_challenge(challenge_id):
		AudioDirector.play_upgrade()
		status_label.text = "Recompensa reclamada."
	else:
		status_label.text = "No se pudo reclamar la recompensa."
	_rebuild()


func _on_back_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(HUB_SCENE)
