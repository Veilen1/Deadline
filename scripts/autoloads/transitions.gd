extends Node

## Transiciones suaves entre escenas. Overlay por encima de todo.
## Si una transición se traba, el watchdog libera el overlay y las
## peticiones que lleguen mientras tanto quedan encoladas.

const WATCHDOG_TIME: float = 3.0

var _overlay: ColorRect
var _watchdog: Timer
var _busy: bool = false
var _active_path: String = ""
var _active_reload: bool = false
var _pending_path: String = ""
var _pending_reload: bool = false
## Escenas ya cargadas: evita volver a leer el disco en cada transición
## (útil si el proyecto vive en una carpeta sincronizada tipo OneDrive).
var _scene_cache: Dictionary = {}


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

	_watchdog = Timer.new()
	_watchdog.one_shot = true
	_watchdog.wait_time = WATCHDOG_TIME
	_watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	_watchdog.timeout.connect(_on_watchdog_timeout)
	add_child(_watchdog)

	_overlay.modulate.a = 1.0
	await get_tree().process_frame
	await _fade_to(0.0, 0.25)
	_overlay.hide()


func change_scene_to_file(path: String) -> void:
	if _busy:
		# No descarta el pedido: lo ejecuta al terminar la transición actual.
		if path != _active_path:
			_pending_path = path
			_pending_reload = false
		return

	_begin(path, false)
	await _fade_to(1.0, 0.18)
	_change_scene(path)
	await get_tree().process_frame
	await _fade_to(0.0, 0.25)
	_end()
	_run_pending()


func reload_current_scene() -> void:
	if _busy:
		if not _active_reload:
			_pending_reload = true
			_pending_path = ""
		return

	_begin("", true)
	await _fade_to(1.0, 0.18)
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await _fade_to(0.0, 0.25)
	_end()
	_run_pending()


func _change_scene(path: String) -> void:
	var started_ms: int = Time.get_ticks_msec()
	var was_cached: bool = _scene_cache.has(path)
	var packed: PackedScene = _scene_cache.get(path) as PackedScene
	if packed == null:
		packed = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
		if packed != null:
			_scene_cache[path] = packed

	if packed != null:
		get_tree().change_scene_to_packed(packed)
	else:
		# Fallback: deja que el árbol resuelva la ruta como siempre.
		get_tree().change_scene_to_file(path)

	Diagnostics.mark("scene_swap", {
		"path": path,
		"cached": was_cached,
		"ms": Time.get_ticks_msec() - started_ms,
	})


func _begin(path: String, reload: bool) -> void:
	Diagnostics.mark("transition_begin", {"path": path, "reload": reload})
	_busy = true
	_active_path = path
	_active_reload = reload
	_pending_path = ""
	_pending_reload = false
	_overlay.show()
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_watchdog.start()


func _end() -> void:
	Diagnostics.mark("transition_end", {"path": _active_path, "reload": _active_reload})
	_watchdog.stop()
	_overlay.hide()
	_busy = false
	_active_path = ""
	_active_reload = false


func _on_watchdog_timeout() -> void:
	# Red de seguridad: una transición no debería tardar más que esto.
	Diagnostics.mark("transition_watchdog", {"path": _active_path, "reload": _active_reload})
	push_warning("Transitions: transición atascada; se libera el overlay.")
	_busy = false
	_active_path = ""
	_active_reload = false
	_overlay.hide()
	_run_pending()


func _run_pending() -> void:
	if _pending_reload:
		_pending_reload = false
		reload_current_scene()
		return
	if not _pending_path.is_empty():
		var path: String = _pending_path
		_pending_path = ""
		change_scene_to_file(path)


func _fade_to(alpha: float, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", alpha, duration)
	await tween.finished
