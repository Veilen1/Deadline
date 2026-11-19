extends Control

const GAME_SCENE: String = "res://scenes/main.tscn"

@onready var play_button: Button = $CenterContainer/Menu/PlayButton
@onready var quit_button: Button = $CenterContainer/Menu/QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
