extends Node

## Configuración persistente del jugador. Se aplica al arrancar y desde
## la pantalla de configuración.

signal settings_changed

const DEFAULT_SAVE_PATH: String = "user://deadline_settings.cfg"
const SAVE_VERSION: int = 1

var save_path: String = DEFAULT_SAVE_PATH
var persistence_enabled: bool = true

# Pantalla
var fov: float = 75.0
var ui_scale: float = 1.0
var fullscreen: bool = false
var vsync: bool = true

# Controles
var mouse_sensitivity: float = 0.003
var invert_y: bool = false

# Audio
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# HUD
var show_minimap: bool = true

# Balance: 0 = fácil, 1 = normal, 2 = difícil
var difficulty: int = 1

var _is_loading: bool = false


func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_display()
	apply_audio()


func apply_display() -> void:
	if not is_inside_tree():
		return

	var window: Window = get_window()
	if window == null:
		return

	window.content_scale_factor = clampf(ui_scale, 0.8, 1.4)

	if DisplayServer.get_name() != "headless":
		window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
		)


func apply_audio() -> void:
	_ensure_audio_buses()
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)


func _ensure_audio_buses() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")


func _ensure_bus(bus_name: String) -> int:
	if bus_name == "Master":
		return AudioServer.get_bus_index("Master")
	var index: int = AudioServer.get_bus_index(bus_name)
	if index >= 0:
		if AudioServer.get_bus_send(index) != "Master":
			AudioServer.set_bus_send(index, "Master")
		return index
	AudioServer.add_bus()
	index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
	return index


func _set_bus_volume(bus_name: String, volume: float) -> void:
	var index: int = _ensure_bus(bus_name)
	var clamped: float = clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_mute(index, clamped <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(clamped, 0.001)))


func enemy_health_multiplier() -> float:
	match difficulty:
		0:
			return 0.8
		2:
			return 1.25
		_:
			return 1.0


func enemy_damage_multiplier() -> float:
	match difficulty:
		0:
			return 0.75
		2:
			return 1.3
		_:
			return 1.0


func difficulty_name(level: int = -1) -> String:
	var value: int = difficulty if level < 0 else level
	match value:
		0:
			return "Fácil"
		2:
			return "Difícil"
		_:
			return "Normal"


func reset_defaults() -> void:
	_is_loading = true
	fov = 75.0
	mouse_sensitivity = 0.003
	ui_scale = 1.0
	master_volume = 1.0
	music_volume = 0.8
	sfx_volume = 1.0
	invert_y = false
	fullscreen = false
	vsync = true
	show_minimap = true
	difficulty = 1
	_is_loading = false

	apply_display()
	apply_audio()
	save_settings()


func save_settings() -> void:
	if _is_loading:
		return

	if persistence_enabled:
		var config := ConfigFile.new()
		config.set_value("settings", "version", SAVE_VERSION)
		config.set_value("settings", "fov", fov)
		config.set_value("settings", "ui_scale", ui_scale)
		config.set_value("settings", "fullscreen", fullscreen)
		config.set_value("settings", "vsync", vsync)
		config.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
		config.set_value("settings", "invert_y", invert_y)
		config.set_value("settings", "master_volume", master_volume)
		config.set_value("settings", "music_volume", music_volume)
		config.set_value("settings", "sfx_volume", sfx_volume)
		config.set_value("settings", "show_minimap", show_minimap)
		config.set_value("settings", "difficulty", difficulty)

		var error: int = config.save(save_path)
		if error != OK:
			push_warning("Settings: no se pudo guardar la configuración (%s)" % error)

	# Permite que la partida en curso aplique FOV, sensibilidad y minimapa al instante.
	settings_changed.emit()


func load_settings() -> void:
	if not persistence_enabled:
		return

	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return

	_is_loading = true
	fov = clampf(float(config.get_value("settings", "fov", 75.0)), 60.0, 110.0)
	ui_scale = clampf(float(config.get_value("settings", "ui_scale", 1.0)), 0.8, 1.4)
	fullscreen = bool(config.get_value("settings", "fullscreen", false))
	vsync = bool(config.get_value("settings", "vsync", true))
	mouse_sensitivity = clampf(float(config.get_value("settings", "mouse_sensitivity", 0.003)), 0.0005, 0.01)
	invert_y = bool(config.get_value("settings", "invert_y", false))
	master_volume = clampf(float(config.get_value("settings", "master_volume", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("settings", "music_volume", 0.8)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("settings", "sfx_volume", 1.0)), 0.0, 1.0)
	show_minimap = bool(config.get_value("settings", "show_minimap", true))
	difficulty = clampi(int(config.get_value("settings", "difficulty", 1)), 0, 2)
	_is_loading = false


func _exit_tree() -> void:
	save_settings()
