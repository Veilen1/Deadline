extends Control

signal chosen(blessing_id: String)

const OPTION_HEIGHT: float = 78.0

@onready var options: VBoxContainer = $CenterContainer/VBox/Options
@onready var subtitle: Label = $CenterContainer/VBox/Subtitle

var _buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func choose() -> String:
	_build_options()
	subtitle.text = "Elegí una mejora para el resto de la run."
	show()
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	if not _buttons.is_empty():
		_buttons[0].grab_focus()
		if DisplayServer.get_name() != "headless":
			Input.warp_mouse(_buttons[0].get_global_rect().get_center())
	return await chosen


func _build_options() -> void:
	for child in options.get_children():
		child.free()
	_buttons.clear()

	for blessing_id in BlessingRegistry.random_ids(3):
		var data: Dictionary = BlessingRegistry.get_data(blessing_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, OPTION_HEIGHT)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		button.text = "%s  %s\n%s" % [
			str(data.get("symbol", "?")),
			str(data.get("title", blessing_id)),
			str(data.get("description", "")),
		]
		button.pressed.connect(_on_option_pressed.bind(blessing_id))
		options.add_child(button)
		_buttons.append(button)


func _on_option_pressed(blessing_id: String) -> void:
	hide()
	chosen.emit(blessing_id)
