extends Node

## Notificaciones flotantes de logros. Se apilan arriba a la derecha y se
## autodestruyen. Funcionan incluso con el juego pausado.

const MAX_TOASTS: int = 4
const TOAST_WIDTH: float = 360.0
const TOAST_DURATION: float = 4.5

var _container: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	_container = VBoxContainer.new()
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.anchor_left = 1.0
	_container.anchor_right = 1.0
	_container.offset_left = -TOAST_WIDTH - 16.0
	_container.offset_right = -16.0
	_container.offset_top = 124.0
	_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_container.add_theme_constant_override("separation", 8)
	root.add_child(_container)

	GameState.challenge_unlocked.connect(_on_challenge_unlocked)


func _on_challenge_unlocked(challenge_id: String) -> void:
	var data: Dictionary = ChallengeRegistry.get_data(challenge_id)
	if data.is_empty():
		return

	var reward_type: String = str(data.get("reward_type", ""))
	var reward_id: String = str(data.get("reward_id", ""))
	var title: String = str(data.get("title", challenge_id))
	var description: String = str(data.get("description", ""))
	var accent: Color = Color(0.3, 0.85, 0.8, 1)
	var footer: String = ""

	if reward_type == "weapon":
		var weapon: WeaponData = WeaponRegistry.get_data(reward_id)
		var weapon_name: String = weapon.weapon_name if weapon != null else reward_id
		title = "%s desbloqueada" % weapon_name
		footer = "Ya está disponible en la tienda."
		accent = Color(0.95, 0.75, 0.25, 1)
	elif reward_type == "cores":
		footer = "Recompensa: ◈%s · reclamala en Desafíos." % reward_id

	show_toast("DESAFÍO COMPLETADO", title, description, footer, accent)


func show_toast(
	kind: String,
	title: String,
	body: String,
	footer: String = "",
	accent: Color = Color(0.3, 0.85, 0.8, 1)
) -> void:
	if _container == null:
		return

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.96)
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", style)
	_container.add_child(panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var kind_label := Label.new()
	kind_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kind_label.text = kind
	kind_label.add_theme_color_override("font_color", accent)
	kind_label.add_theme_font_size_override("font_size", 11)
	box.add_child(kind_label)

	var title_label := Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1))
	title_label.add_theme_font_size_override("font_size", 17)
	box.add_child(title_label)

	var body_label := Label.new()
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", Color(0.7, 0.77, 0.87, 1))
	body_label.add_theme_font_size_override("font_size", 12)
	box.add_child(body_label)

	if not footer.is_empty():
		var footer_label := Label.new()
		footer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		footer_label.text = footer
		footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		footer_label.add_theme_color_override("font_color", accent)
		footer_label.add_theme_font_size_override("font_size", 11)
		box.add_child(footer_label)

	# Si se acumulan demasiados, libera el más viejo.
	while _container.get_child_count() > MAX_TOASTS:
		var oldest: Node = _container.get_child(0)
		_container.remove_child(oldest)
		oldest.queue_free()

	panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(TOAST_DURATION)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(panel.queue_free)
