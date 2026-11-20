extends Control

const HUB_SCENE: String = "res://scenes/ui/hub.tscn"

@onready var money_label: Label = $Margin/VBox/TopBar/MoneyLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var weapon_list: VBoxContainer = $Margin/VBox/Scroll/List
@onready var status_label: Label = $Margin/VBox/StatusLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.money_changed.connect(_on_money_changed)
	back_button.pressed.connect(_on_back_pressed)
	_rebuild()


func _on_money_changed(_new_amount: int) -> void:
	_rebuild()


func _rebuild() -> void:
	money_label.text = "$%d" % GameState.money

	for child in weapon_list.get_children():
		child.queue_free()

	for weapon_id in WeaponRegistry.ids():
		_build_card(str(weapon_id))


func _build_card(weapon_id: String) -> void:
	var data: WeaponData = WeaponRegistry.get_data(weapon_id)
	if data == null:
		return

	var owned: bool = GameState.is_weapon_owned(weapon_id)
	var equipped: bool = GameState.equipped_weapon == weapon_id
	var unlocked: bool = GameState.is_weapon_unlocked(weapon_id)

	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.07, 0.1, 0.16, 1)
	card_style.border_color = Color(0.95, 0.75, 0.25, 1) if equipped else Color(0.22, 0.32, 0.46, 1)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_right = 6
	card_style.corner_radius_bottom_left = 6
	card.add_theme_stylebox_override("panel", card_style)

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
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = data.weapon_name
	name_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25, 1))
	name_label.add_theme_font_size_override("font_size", 22)
	info.add_child(name_label)

	var description := Label.new()
	description.text = data.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color(0.68, 0.75, 0.85, 1))
	description.add_theme_font_size_override("font_size", 14)
	info.add_child(description)

	var stats := Label.new()
	stats.text = "Daño %d · %d disparos/s · %d balas · regen %.0f/s" % [
		int(data.damage),
		int(round(data.shots_per_second)),
		data.magazine_size,
		data.ammo_regen_per_second,
	]
	stats.add_theme_color_override("font_color", Color(0.3, 0.85, 0.8, 1))
	stats.add_theme_font_size_override("font_size", 14)
	info.add_child(stats)

	if not unlocked:
		var unlock_id: String = ChallengeRegistry.weapon_unlock_for(weapon_id)
		var unlock_data: Dictionary = ChallengeRegistry.get_data(unlock_id)
		var requirement := Label.new()
		requirement.text = "Bloqueada · %s (%d/%d)" % [
			str(unlock_data.get("description", "Completá el desafío")),
			GameState.get_challenge_progress(unlock_id),
			int(unlock_data.get("target", 1)),
		]
		requirement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		requirement.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35, 1))
		requirement.add_theme_font_size_override("font_size", 13)
		info.add_child(requirement)

	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(160, 0)
	actions.add_theme_constant_override("separation", 8)
	row.add_child(actions)

	var price_label := Label.new()
	if equipped:
		price_label.text = "EQUIPADA"
	elif owned:
		price_label.text = "COMPRADA"
	elif not unlocked:
		price_label.text = "BLOQUEADA"
	else:
		price_label.text = "$%d" % data.price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.75, 0.25, 1) if equipped else Color(0.86, 0.9, 0.96, 1)
	)
	actions.add_child(price_label)

	if not unlocked:
		var locked_label := Label.new()
		locked_label.text = "Completá el desafío"
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		locked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked_label.add_theme_color_override("font_color", Color(0.85, 0.5, 0.35, 1))
		locked_label.add_theme_font_size_override("font_size", 13)
		actions.add_child(locked_label)
	elif not owned:
		var buy_button := Button.new()
		buy_button.text = "Comprar"
		buy_button.custom_minimum_size = Vector2(150, 38)
		buy_button.theme_type_variation = "SecondaryButton"
		buy_button.disabled = GameState.money < data.price
		buy_button.pressed.connect(_on_buy_pressed.bind(weapon_id))
		actions.add_child(buy_button)
	elif not equipped:
		var equip_button := Button.new()
		equip_button.text = "Equipar"
		equip_button.custom_minimum_size = Vector2(150, 38)
		equip_button.theme_type_variation = "SecondaryButton"
		equip_button.pressed.connect(_on_equip_pressed.bind(weapon_id))
		actions.add_child(equip_button)
	else:
		var in_use := Label.new()
		in_use.text = "EN USO"
		in_use.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		in_use.add_theme_color_override("font_color", Color(0.3, 0.85, 0.8, 1))
		in_use.add_theme_font_size_override("font_size", 14)
		actions.add_child(in_use)

	weapon_list.add_child(card)


func _on_buy_pressed(weapon_id: String) -> void:
	var data: WeaponData = WeaponRegistry.get_data(weapon_id)
	var title: String = data.weapon_name if data != null else weapon_id
	if GameState.buy_weapon(weapon_id):
		AudioDirector.play_upgrade()
		status_label.text = "Compraste %s. Ya podés equiparla." % title
	else:
		status_label.text = "No alcanza la plata para %s." % title
	_rebuild()


func _on_equip_pressed(weapon_id: String) -> void:
	var data: WeaponData = WeaponRegistry.get_data(weapon_id)
	var title: String = data.weapon_name if data != null else weapon_id
	if GameState.equip_weapon(weapon_id):
		status_label.text = "%s equipada. Se usa en la próxima run." % title
	else:
		status_label.text = "No se pudo equipar %s." % title
	_rebuild()


func _on_back_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(HUB_SCENE)
