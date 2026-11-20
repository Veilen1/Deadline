extends Node

## Transiciones suaves entre escenas. Overlay por encima de todo.

var _overlay: ColorRect
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.04, 0.07, 1.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_overlay)

	_overlay.modulate.a = 1.0
	await get_tree().process_frame
	await _fade_to(0.0, 0.25)
	_overlay.hide()


func change_scene_to_file(path: String) -> void:
	if _busy:
		return
	_busy = true
	_overlay.show()
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, 0.18)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await _fade_to(0.0, 0.25)
	_overlay.hide()
	_busy = false


func reload_current_scene() -> void:
	if _busy:
		return
	_busy = true
	_overlay.show()
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, 0.18)
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await _fade_to(0.0, 0.25)
	_overlay.hide()
	_busy = false


func _fade_to(alpha: float, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", alpha, duration)
	await tween.finished
