extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const HUB_SCENE: String = "res://scenes/ui/hub.tscn"
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings.tscn")

@onready var resume_button: Button = $CenterContainer/Menu/ResumeButton
@onready var restart_button: Button = $CenterContainer/Menu/RestartButton
@onready var config_button: Button = $CenterContainer/Menu/ConfigButton
@onready var hub_button: Button = $CenterContainer/Menu/HubButton
@onready var main_menu_button: Button = $CenterContainer/Menu/MainMenuButton

var _settings_menu: Control
var _settings_open: bool = false


func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	config_button.pressed.connect(_on_config_pressed)
	hub_button.pressed.connect(_on_hub_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if _settings_open:
		return

	if not event.is_action_pressed("ui_cancel"):
		return

	if visible:
		_resume_game()
	else:
		_pause_game()

	get_viewport().set_input_as_handled()


func _pause_game() -> void:
	get_tree().paused = true
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()


func _resume_game() -> void:
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_resume_pressed() -> void:
	_resume_game()


func _on_restart_pressed() -> void:
	GameState.abandon_run()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_config_pressed() -> void:
	if _settings_open:
		return

	_settings_open = true
	_settings_menu = SETTINGS_SCENE.instantiate() as Control
	_settings_menu.set("overlay_mode", true)
	_settings_menu.closed.connect(_on_settings_closed)
	get_parent().add_child(_settings_menu)
	hide()


func _on_settings_closed() -> void:
	_close_settings()
	show()
	config_button.grab_focus()


func _close_settings() -> void:
	if is_instance_valid(_settings_menu):
		_settings_menu.queue_free()
	_settings_menu = null
	_settings_open = false


func _on_hub_pressed() -> void:
	GameState.abandon_run()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(HUB_SCENE)


func _on_main_menu_pressed() -> void:
	GameState.abandon_run()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func set_enabled(enabled: bool) -> void:
	# Al terminar la run la pausa se desactiva para no competir con fin de run.
	process_mode = Node.PROCESS_MODE_ALWAYS if enabled else Node.PROCESS_MODE_DISABLED
	if not enabled:
		_close_settings()
		hide()
