extends Node

## Log liviano de diagnóstico. Registra hitches de frame y los hitos del
## fin de run para poder revisar qué pasó si el juego se traba.
## El archivo se reescribe en cada arranque: user://deadline_diag.log

const LOG_PATH: String = "user://deadline_diag.log"
const STALL_MS: int = 350
## Con la ventana sin foco el sistema puede frenar el render; esos stalls se
## registran aparte y solo si son graves, para no ensuciar el diagnóstico.
const BG_STALL_MS: int = 1000
const MAX_LINES: int = 800

var _file: FileAccess
var _start_ms: int = 0
var _last_ms: int = 0
var _lines: int = 0
var _focused: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_ms = Time.get_ticks_msec()
	_last_ms = _start_ms
	_focused = get_window().has_focus()
	mark("boot", {
		"version": str(ProjectSettings.get_setting("application/config/name", "")),
		"window": str(get_window().size),
		"focused": _focused,
	})
	mark("diag_path", {"path": ProjectSettings.globalize_path(LOG_PATH)})


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var elapsed: int = now - _last_ms
	_last_ms = now

	var focused: bool = get_window().has_focus()
	if focused != _focused:
		_focused = focused
		mark("focus", {
			"focused": focused,
			"scene": _scene_name(),
			"paused": get_tree().paused,
			"elapsed_ms": mini(elapsed, 60000),
		})

	if elapsed < STALL_MS:
		return
	if not focused and elapsed < BG_STALL_MS:
		return

	mark("stall" if focused else "stall_bg", {
		"ms": elapsed,
		"scene": _scene_name(),
		"paused": get_tree().paused,
		"focused": focused,
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"fps": Engine.get_frames_per_second(),
		"enemies": get_tree().get_nodes_in_group("enemies").size(),
		"projectiles": get_tree().get_nodes_in_group("enemy_projectiles").size(),
		"audio3d": _count_audio3d(),
		# Si process_ms es chico pero el frame es enorme, el bloqueo no está en
		# los scripts: viene del motor, del driver o del sistema operativo.
		"process_ms": snappedf(
			float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0, 0.1
		),
		"physics_ms": snappedf(
			float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0, 0.1
		),
		"draw_calls": int(
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		),
		"mem_mb": int(
			float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
		),
	})


func mark(event: String, data: Dictionary = {}) -> void:
	_ensure_file()
	if _file == null:
		return

	var elapsed: int = Time.get_ticks_msec() - _start_ms
	var parts: Array[String] = ["%08d" % elapsed, event]
	for key in data:
		parts.append("%s=%s" % [str(key), str(data[key])])
	_file.store_line(" ".join(PackedStringArray(parts)))
	_file.flush()
	_lines += 1

	if _lines >= MAX_LINES:
		# Evita que el log crezca sin límite en sesiones largas.
		_file.close()
		_file = null
		var dir: DirAccess = DirAccess.open("user://")
		if dir != null:
			dir.remove(LOG_PATH.get_file())
		_lines = 0
		_ensure_file()
		if _file != null:
			_file.store_line("--- log truncado ---")
			_file.flush()
			_lines = 1


func _ensure_file() -> void:
	if _file != null:
		return
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)


func _scene_name() -> String:
	var scene: Node = get_tree().current_scene
	return scene.name if scene != null else "none"


func _count_audio3d() -> int:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return 0
	var count: int = 0
	for child in scene.get_children():
		if child is AudioStreamPlayer3D:
			count += 1
	return count


func _exit_tree() -> void:
	if _file != null:
		_file.close()
		_file = null
