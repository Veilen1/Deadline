extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var fov_slider: HSlider = $CenterContainer/Menu/OptionsScroll/Options/FovRow/FovSlider
@onready var fov_value: Label = $CenterContainer/Menu/OptionsScroll/Options/FovRow/FovValue
@onready var sensitivity_slider: HSlider = $CenterContainer/Menu/OptionsScroll/Options/SensitivityRow/SensitivitySlider
@onready var sensitivity_value: Label = $CenterContainer/Menu/OptionsScroll/Options/SensitivityRow/SensitivityValue
@onready var ui_scale_slider: HSlider = $CenterContainer/Menu/OptionsScroll/Options/UIScaleRow/UIScaleSlider
@onready var ui_scale_value: Label = $CenterContainer/Menu/OptionsScroll/Options/UIScaleRow/UIScaleValue
@onready var volume_slider: HSlider = $CenterContainer/Menu/OptionsScroll/Options/VolumeRow/VolumeSlider
@onready var volume_value: Label = $CenterContainer/Menu/OptionsScroll/Options/VolumeRow/VolumeValue
@onready var invert_check: CheckButton = $CenterContainer/Menu/OptionsScroll/Options/InvertRow/InvertCheck
@onready var fullscreen_check: CheckButton = $CenterContainer/Menu/OptionsScroll/Options/FullscreenRow/FullscreenCheck
@onready var vsync_check: CheckButton = $CenterContainer/Menu/OptionsScroll/Options/VsyncRow/VsyncCheck
@onready var minimap_check: CheckButton = $CenterContainer/Menu/OptionsScroll/Options/MinimapRow/MinimapCheck
@onready var difficulty_option: OptionButton = $CenterContainer/Menu/OptionsScroll/Options/DifficultyRow/DifficultyOption
@onready var status_label: Label = $CenterContainer/Menu/StatusLabel
@onready var defaults_button: Button = $CenterContainer/Menu/Buttons/DefaultsButton
@onready var reset_button: Button = $CenterContainer/Menu/Buttons/ResetButton
@onready var back_button: Button = $CenterContainer/Menu/Buttons/BackButton
@onready var reset_dialog: ConfirmationDialog = $ResetDialog

var _updating: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_populate_difficulty()
	_load_controls()

	fov_slider.value_changed.connect(_on_fov_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	invert_check.toggled.connect(_on_invert_toggled)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	minimap_check.toggled.connect(_on_minimap_toggled)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	defaults_button.pressed.connect(_on_defaults_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	reset_dialog.confirmed.connect(_on_reset_confirmed)

	back_button.grab_focus()


func _populate_difficulty() -> void:
	difficulty_option.clear()
	difficulty_option.add_item("Fácil")
	difficulty_option.add_item("Normal")
	difficulty_option.add_item("Difícil")


func _load_controls() -> void:
	_updating = true
	fov_slider.value = Settings.fov
	sensitivity_slider.value = Settings.mouse_sensitivity
	ui_scale_slider.value = Settings.ui_scale
	volume_slider.value = Settings.master_volume
	invert_check.button_pressed = Settings.invert_y
	fullscreen_check.button_pressed = Settings.fullscreen
	vsync_check.button_pressed = Settings.vsync
	minimap_check.button_pressed = Settings.show_minimap
	difficulty_option.select(clampi(Settings.difficulty, 0, 2))
	_update_value_labels()
	_updating = false


func _update_value_labels() -> void:
	fov_value.text = "%d°" % int(round(fov_slider.value))
	sensitivity_value.text = "%.4f" % sensitivity_slider.value
	ui_scale_value.text = "%d%%" % int(round(ui_scale_slider.value * 100.0))
	volume_value.text = "%d%%" % int(round(volume_slider.value * 100.0))


func _on_fov_changed(value: float) -> void:
	if _updating:
		return
	Settings.fov = value
	_update_value_labels()
	Settings.save_settings()


func _on_sensitivity_changed(value: float) -> void:
	if _updating:
		return
	Settings.mouse_sensitivity = value
	_update_value_labels()
	Settings.save_settings()


func _on_ui_scale_changed(value: float) -> void:
	if _updating:
		return
	Settings.ui_scale = value
	_update_value_labels()
	Settings.apply_display()
	Settings.save_settings()


func _on_volume_changed(value: float) -> void:
	if _updating:
		return
	Settings.master_volume = value
	_update_value_labels()
	Settings.apply_audio()
	Settings.save_settings()


func _on_invert_toggled(pressed: bool) -> void:
	if _updating:
		return
	Settings.invert_y = pressed
	Settings.save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	if _updating:
		return
	Settings.fullscreen = pressed
	Settings.apply_display()
	Settings.save_settings()


func _on_vsync_toggled(pressed: bool) -> void:
	if _updating:
		return
	Settings.vsync = pressed
	Settings.apply_display()
	Settings.save_settings()


func _on_minimap_toggled(pressed: bool) -> void:
	if _updating:
		return
	Settings.show_minimap = pressed
	Settings.save_settings()


func _on_difficulty_selected(index: int) -> void:
	if _updating:
		return
	Settings.difficulty = index
	Settings.save_settings()


func _on_defaults_pressed() -> void:
	Settings.reset_defaults()
	_load_controls()
	status_label.text = "Ajustes restablecidos."


func _on_reset_pressed() -> void:
	reset_dialog.popup_centered(Vector2i(460, 150))


func _on_reset_confirmed() -> void:
	GameState.reset_progress()
	status_label.text = "Progreso borrado."


func _on_back_pressed() -> void:
	Settings.save_settings()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
