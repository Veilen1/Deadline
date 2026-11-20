extends Node

## Sonidos de UI globales. Se auto-conectan a todos los botones nuevos.

var _hover_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_hover_player = AudioStreamPlayer.new()
	_hover_player.stream = preload("res://assets/audio/ui_hover.wav")
	_hover_player.volume_db = -20.0
	_hover_player.bus = "SFX"
	add_child(_hover_player)

	_click_player = AudioStreamPlayer.new()
	_click_player.stream = preload("res://assets/audio/ui_click.wav")
	_click_player.volume_db = -12.0
	_click_player.bus = "SFX"
	add_child(_click_player)

	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if not node is BaseButton:
		return

	var hover_callable := Callable(self, "_play_hover")
	var click_callable := Callable(self, "_play_click")
	var button := node as BaseButton

	if not button.mouse_entered.is_connected(hover_callable):
		button.mouse_entered.connect(hover_callable)
	if not button.pressed.is_connected(click_callable):
		button.pressed.connect(click_callable)


func _play_hover() -> void:
	_hover_player.play()


func _play_click() -> void:
	_click_player.play()
