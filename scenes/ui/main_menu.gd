extends Control

const GAME_SCENE: String = "res://scenes/ui/hub.tscn"

@onready var play_button: Button = $CenterContainer/Card/VBox/PlayButton
@onready var config_button: Button = $CenterContainer/Card/VBox/SecondaryRow/ConfigButton
@onready var profile_button: Button = $CenterContainer/Card/VBox/SecondaryRow/ProfileButton
@onready var quit_button: Button = $CenterContainer/Card/VBox/QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.reset_mood()
	play_button.pressed.connect(_on_play_pressed)
	config_button.pressed.connect(_on_config_pressed)
	profile_button.pressed.connect(_on_profile_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()


func _on_play_pressed() -> void:
	Transitions.change_scene_to_file(GAME_SCENE)


func _on_config_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file("res://scenes/ui/settings.tscn")


func _on_profile_pressed() -> void:
	GameState.save_game()
	Transitions.change_scene_to_file("res://scenes/ui/profile.tscn")


func _on_quit_pressed() -> void:
	GameState.save_game()
	get_tree().quit()
