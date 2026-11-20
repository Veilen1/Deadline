extends Node

## Tema global del juego: azul noche, dorado y turquesa. Se aplica al root
## para que todos los Controls hereden el mismo estilo.

const BG_DARK: Color = Color(0.043, 0.071, 0.125, 1.0)
const BG_PANEL: Color = Color(0.06, 0.09, 0.14, 1.0)
const BG_BUTTON: Color = Color(0.08, 0.12, 0.19, 1.0)
const BG_BUTTON_HOVER: Color = Color(0.13, 0.19, 0.28, 1.0)
const BORDER: Color = Color(0.22, 0.32, 0.48, 1.0)
const TEXT: Color = Color(0.9, 0.94, 0.99, 1.0)
const MUTED: Color = Color(0.62, 0.72, 0.82, 1.0)
const GOLD: Color = Color(0.95, 0.75, 0.25, 1.0)
const TEAL: Color = Color(0.3, 0.85, 0.8, 1.0)


var _global_theme: Theme


func _ready() -> void:
	var theme := Theme.new()

	theme.set_color("font_color", "Label", TEXT)
	theme.set_font_size("font_size", "Label", 16)

	theme.set_stylebox("normal", "Button", _box(BG_BUTTON, BORDER, 1, 5))
	theme.set_stylebox("hover", "Button", _box(BG_BUTTON_HOVER, TEAL, 1, 5))
	theme.set_stylebox("pressed", "Button", _box(Color(0.05, 0.08, 0.13, 1.0), GOLD, 1, 5))
	theme.set_stylebox("disabled", "Button", _box(Color(0.06, 0.08, 0.12, 1.0), Color(0.15, 0.2, 0.28, 1.0), 1, 5))
	theme.set_stylebox("focus", "Button", _focus_box(TEAL, 5))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.96, 0.82, 1.0))
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", Color(0.45, 0.52, 0.62, 1.0))
	theme.set_font_size("font_size", "Button", 17)

	# Variaciones de botón para jerarquía visual en todos los menús.
	theme.set_type_variation("PrimaryButton", "Button")
	theme.set_stylebox("normal", "PrimaryButton", _box(Color(0.12, 0.095, 0.035, 1.0), GOLD, 2, 7, 18, 10))
	theme.set_stylebox("hover", "PrimaryButton", _box(Color(0.2, 0.16, 0.06, 1.0), Color(1.0, 0.86, 0.4, 1.0), 2, 7, 18, 10))
	theme.set_stylebox("pressed", "PrimaryButton", _box(Color(0.08, 0.06, 0.02, 1.0), GOLD, 2, 7, 18, 10))
	theme.set_stylebox("disabled", "PrimaryButton", _box(Color(0.06, 0.07, 0.09, 1.0), Color(0.2, 0.2, 0.22, 1.0), 1, 7, 18, 10))
	theme.set_stylebox("focus", "PrimaryButton", _focus_box(GOLD, 7))
	theme.set_color("font_color", "PrimaryButton", Color(1.0, 0.9, 0.55, 1.0))
	theme.set_color("font_hover_color", "PrimaryButton", Color(1.0, 0.98, 0.85, 1.0))
	theme.set_color("font_pressed_color", "PrimaryButton", GOLD)
	theme.set_color("font_disabled_color", "PrimaryButton", Color(0.5, 0.5, 0.55, 1.0))
	theme.set_font_size("font_size", "PrimaryButton", 18)

	theme.set_type_variation("SecondaryButton", "Button")
	theme.set_stylebox("normal", "SecondaryButton", _box(BG_BUTTON, BORDER, 1, 7, 14, 8))
	theme.set_stylebox("hover", "SecondaryButton", _box(BG_BUTTON_HOVER, TEAL, 1, 7, 14, 8))
	theme.set_stylebox("pressed", "SecondaryButton", _box(Color(0.05, 0.08, 0.13, 1.0), GOLD, 1, 7, 14, 8))
	theme.set_stylebox("disabled", "SecondaryButton", _box(Color(0.06, 0.08, 0.12, 1.0), Color(0.15, 0.2, 0.28, 1.0), 1, 7, 14, 8))
	theme.set_stylebox("focus", "SecondaryButton", _focus_box(TEAL, 7))
	theme.set_color("font_color", "SecondaryButton", TEXT)
	theme.set_color("font_hover_color", "SecondaryButton", Color(1.0, 0.96, 0.82, 1.0))
	theme.set_color("font_pressed_color", "SecondaryButton", GOLD)
	theme.set_color("font_disabled_color", "SecondaryButton", Color(0.45, 0.52, 0.62, 1.0))
	theme.set_font_size("font_size", "SecondaryButton", 15)

	theme.set_type_variation("TextButton", "Button")
	theme.set_stylebox("normal", "TextButton", _box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 5, 10, 6))
	theme.set_stylebox("hover", "TextButton", _box(Color(0.1, 0.15, 0.22, 0.55), Color(0, 0, 0, 0), 0, 5, 10, 6))
	theme.set_stylebox("pressed", "TextButton", _box(Color(0.06, 0.09, 0.14, 0.8), Color(0, 0, 0, 0), 0, 5, 10, 6))
	theme.set_stylebox("disabled", "TextButton", _box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 5, 10, 6))
	theme.set_stylebox("focus", "TextButton", _focus_box(TEAL, 5))
	theme.set_color("font_color", "TextButton", MUTED)
	theme.set_color("font_hover_color", "TextButton", TEXT)
	theme.set_color("font_pressed_color", "TextButton", GOLD)
	theme.set_font_size("font_size", "TextButton", 14)

	# Tarjetas reutilizables para los menús.
	theme.set_type_variation("CardPanel", "PanelContainer")
	theme.set_stylebox("panel", "CardPanel", _box(Color(0.055, 0.08, 0.12, 1.0), Color(0.16, 0.24, 0.34, 1.0), 1, 10, 14, 12))
	theme.set_type_variation("HeroPanel", "PanelContainer")
	theme.set_stylebox("panel", "HeroPanel", _box(Color(0.06, 0.09, 0.14, 1.0), Color(0.65, 0.52, 0.2, 1.0), 1, 12, 20, 18))

	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		theme.set_stylebox(style_name, "OptionButton", theme.get_stylebox(style_name, "Button"))
	theme.set_color("font_color", "OptionButton", TEXT)
	theme.set_color("font_hover_color", "OptionButton", Color(1.0, 0.96, 0.82, 1.0))
	theme.set_font_size("font_size", "OptionButton", 16)

	for style_name in ["normal", "focus", "read_only"]:
		theme.set_stylebox(style_name, "LineEdit", _box(BG_BUTTON, BORDER if style_name != "focus" else TEAL, 1, 4))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("caret_color", "LineEdit", TEAL)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)

	theme.set_stylebox("panel", "Panel", _box(BG_PANEL, BORDER, 1, 6))
	theme.set_stylebox("panel", "PanelContainer", _box(BG_PANEL, BORDER, 1, 6))

	theme.set_stylebox("slider", "HSlider", _box(Color(0.1, 0.14, 0.2, 1.0), BORDER, 1, 3, 0, 0))
	theme.set_stylebox("grabber_area", "HSlider", _box(TEAL, TEAL, 0, 3, 0, 0))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _box(Color(0.45, 1.0, 0.92, 1.0), TEAL, 0, 3, 0, 0))

	theme.set_color("font_color", "CheckButton", TEXT)
	theme.set_color("font_pressed_color", "CheckButton", GOLD)
	theme.set_font_size("font_size", "CheckButton", 16)

	theme.set_stylebox("background", "ProgressBar", _box(Color(0.05, 0.08, 0.12, 1.0), BORDER, 1, 3, 0, 0))
	theme.set_stylebox("fill", "ProgressBar", _box(GOLD, GOLD, 0, 3, 0, 0))
	theme.set_color("font_color", "ProgressBar", TEXT)

	get_tree().root.theme = theme
	_global_theme = theme
	# Los menús que cuelgan de CanvasLayer/Node3D no heredan el tema del root.
	get_tree().node_added.connect(_on_node_added)
	_apply_theme_to_existing(get_tree().root)


func _on_node_added(node: Node) -> void:
	_apply_theme_if_needed(node)


func _apply_theme_to_existing(node: Node) -> void:
	for child in node.get_children():
		_apply_theme_if_needed(child)
		_apply_theme_to_existing(child)


func _apply_theme_if_needed(node: Node) -> void:
	if _global_theme == null:
		return
	if node is Window:
		if node != get_tree().root and (node as Window).theme == null:
			(node as Window).theme = _global_theme
		return
	if not node is Control:
		return
	var control := node as Control
	if control.theme != null:
		return
	var parent: Node = control.get_parent()
	if parent is Control or parent is Window:
		return
	# UI instanciada bajo CanvasLayer, Node3D o Node: le damos el tema global.
	control.theme = _global_theme


func _box(bg: Color, border: Color, border_width: int, radius: int, margin_h: int = 12, margin_v: int = 7) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius
	box.content_margin_left = margin_h
	box.content_margin_right = margin_h
	box.content_margin_top = margin_v
	box.content_margin_bottom = margin_v
	return box


func _focus_box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.draw_center = false
	box.border_color = color
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius
	return box
