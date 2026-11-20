extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var name_edit: LineEdit = $Margin/VBox/ProfilePanel/Margin/VBox/NameRow/NameEdit
@onready var stats_grid: GridContainer = $Margin/VBox/ProfilePanel/Margin/VBox/Stats
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var status_label: Label = $Margin/VBox/ProfilePanel/Margin/VBox/StatusLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	name_edit.text = GameState.profile_name
	name_edit.text_changed.connect(_on_name_changed)
	back_button.pressed.connect(_on_back_pressed)
	_update_stats()
	back_button.grab_focus()


func _on_name_changed(text: String) -> void:
	var clean_name: String = text.strip_edges()
	if clean_name.is_empty():
		return
	GameState.profile_name = clean_name
	GameState.save_game()
	status_label.text = "Perfil guardado."


func _update_stats() -> void:
	for child in stats_grid.get_children():
		child.queue_free()

	var equipped_data: WeaponData = WeaponRegistry.get_data(GameState.equipped_weapon)
	var equipped_name: String = equipped_data.weapon_name if equipped_data != null else "—"

	_add_stat("Plata actual", "$%d" % GameState.money)
	_add_stat("Núcleos", "◈ %d" % GameState.cores)
	_add_stat("Recaudado total", "$%d" % GameState.lifetime_earned)
	_add_stat("Runs iniciadas", str(GameState.runs_started))
	_add_stat("Runs completadas", str(GameState.runs_completed))
	_add_stat("Muertes / abandonos", str(GameState.deaths))
	_add_stat("Veces sin tiempo", str(GameState.runs_timed_out))
	_add_stat("Enemigos eliminados", str(GameState.kills))
	_add_stat("Headshots", str(GameState.headshots))
	_add_stat("Élites eliminados", str(GameState.elites_killed))
	_add_stat("Sabuesos eliminados", str(GameState.hounds_killed))
	_add_stat("Zonas completadas", str(GameState.zones_cleared))
	_add_stat("Nodos desbloqueados", str(GameState.get_unlocked_skill_count()))
	_add_stat("Armas compradas", "%d / %d" % [GameState.owned_weapons.size(), WeaponRegistry.ids().size()])
	_add_stat("Arma equipada", equipped_name)
	_add_stat("Timer base", "%.0f s" % GameState.base_run_time)


func _add_stat(label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.65, 0.72, 0.82, 1))
	label.add_theme_font_size_override("font_size", 15)
	stats_grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color(0.92, 0.95, 1, 1))
	value.add_theme_font_size_override("font_size", 15)
	stats_grid.add_child(value)


func _on_back_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file(MAIN_MENU_SCENE)
