extends Control

enum LeaveAction { NONE, HUB, MENU, RESTART }

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const HUB_SCENE: String = "res://scenes/ui/hub.tscn"
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings.tscn")

@onready var resume_button: Button = $CenterContainer/Card/Menu/ResumeButton
@onready var restart_button: Button = $CenterContainer/Card/Menu/RestartButton
@onready var config_button: Button = $CenterContainer/Card/Menu/ConfigButton
@onready var hub_button: Button = $CenterContainer/Card/Menu/HubButton
@onready var main_menu_button: Button = $CenterContainer/Card/Menu/MainMenuButton
@onready var leave_dialog: ConfirmationDialog = $LeaveDialog

var _settings_menu: Control
var _settings_open: bool = false
var _pending_leave: LeaveAction = LeaveAction.NONE


func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	config_button.pressed.connect(_on_config_pressed)
	hub_button.pressed.connect(_on_hub_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	leave_dialog.confirmed.connect(_on_leave_confirmed)


func _unhandled_input(event: InputEvent) -> void:
	if _settings_open or leave_dialog.visible:
		return

	if not event.is_action_pressed("ui_cancel"):
		return

	if visible:
		_resume_game()
	else:
		_pause_game()

	get_viewport().set_input_as_handled()


func _pause_game() -> void:
	Diagnostics.mark("pause_open")
	get_tree().paused = true
	show()
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.12)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Igual que en fin de run: fuerza el cursor visible y sobre el botón.
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		Input.warp_mouse(resume_button.get_global_rect().get_center())
	resume_button.grab_focus()


func _resume_game() -> void:
	Diagnostics.mark("pause_close")
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(hide)


func _on_resume_pressed() -> void:
	_resume_game()


func _on_restart_pressed() -> void:
	_request_leave(LeaveAction.RESTART)


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
	_request_leave(LeaveAction.HUB)


func _on_main_menu_pressed() -> void:
	_request_leave(LeaveAction.MENU)


func _request_leave(action: LeaveAction) -> void:
	if leave_dialog.visible:
		return

	var penalty: int = GameState.get_abandon_penalty()
	if penalty <= 0:
		_execute_leave(action)
		return

	_pending_leave = action
	var earned: int = GameState.get_run_earnings()
	var percent: int = int(round(GameState.death_penalty * 100.0))

	if action == LeaveAction.RESTART:
		leave_dialog.title = "Reiniciar run"
		leave_dialog.ok_button_text = "Sí, reiniciar"
		leave_dialog.dialog_text = "Si reiniciás ahora perderás $%d (%d%% de $%d recaudados en esta run)." % [
			penalty, percent, earned
		]
	else:
		leave_dialog.title = "Abandonar run"
		leave_dialog.ok_button_text = "Sí, salir"
		leave_dialog.dialog_text = "Si vuelves al lobby ahora perderás $%d (%d%% de $%d recaudados en esta run)." % [
			penalty, percent, earned
		]

	leave_dialog.popup_centered(Vector2i(580, 170))


func _on_leave_confirmed() -> void:
	var action: LeaveAction = _pending_leave
	_pending_leave = LeaveAction.NONE
	_execute_leave(action)


func _execute_leave(action: LeaveAction) -> void:
	GameState.abandon_run()

	match action:
		LeaveAction.HUB:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Transitions.change_scene_to_file(HUB_SCENE)
		LeaveAction.MENU:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Transitions.change_scene_to_file(MAIN_MENU_SCENE)
		LeaveAction.RESTART:
			get_tree().paused = false
			Transitions.reload_current_scene()


func set_enabled(enabled: bool) -> void:
	# Al terminar la run la pausa se desactiva para no competir con fin de run.
	process_mode = Node.PROCESS_MODE_ALWAYS if enabled else Node.PROCESS_MODE_DISABLED
	if not enabled:
		leave_dialog.hide()
		_pending_leave = LeaveAction.NONE
		_close_settings()
		hide()
