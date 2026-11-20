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
