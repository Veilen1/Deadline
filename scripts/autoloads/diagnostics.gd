extends Node

## Log liviano de diagnóstico. Registra hitches de frame y los hitos del
## fin de run para poder revisar qué pasó si el juego se traba.
## El archivo se reescribe en cada arranque: user://deadline_diag.log

const LOG_PATH: String = "user://deadline_diag.log"
const STALL_MS: int = 350
const MAX_LINES: int = 800

var _file: FileAccess
var _start_ms: int = 0
var _last_ms: int = 0
var _lines: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_ms = Time.get_ticks_msec()
	_last_ms = _start_ms
	mark("boot", {
		"version": str(ProjectSettings.get_setting("application/config/name", "")),
		"window": str(get_window().size),
	})
	mark("diag_path", {"path": ProjectSettings.globalize_path(LOG_PATH)})


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var elapsed: int = now - _last_ms
	_last_ms = now
	if elapsed < STALL_MS:
		return

	mark("stall", {
		"ms": elapsed,
		"scene": _scene_name(),
		"paused": get_tree().paused,
		"fps": Engine.get_frames_per_second(),
		"enemies": get_tree().get_nodes_in_group("enemies").size(),
		"projectiles": get_tree().get_nodes_in_group("enemy_projectiles").size(),
		"audio3d": _count_audio3d(),
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
