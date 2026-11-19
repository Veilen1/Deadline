extends Control

const HUB_SCENE: String = "res://scenes/ui/hub.tscn"

@onready var reason_label: Label = $CenterContainer/Menu/ReasonLabel
@onready var money_label: Label = $CenterContainer/Menu/MoneyLabel
@onready var retry_button: Button = $CenterContainer/Menu/RetryButton
@onready var hub_button: Button = $CenterContainer/Menu/HubButton


func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_on_retry_pressed)
	hub_button.pressed.connect(_on_hub_pressed)


func show_result(reason: String, money: int) -> void:
	reason_label.text = _reason_text(reason)
	money_label.text = "Plata acumulada: $%d" % money
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	retry_button.grab_focus()


func _reason_text(reason: String) -> String:
	match reason:
		"timer":
			return "Se terminó el tiempo"
		"death":
			return "Moriste"
		"completed":
			return "Run completada"
		_:
			return "Fin de la run"


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_hub_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(HUB_SCENE)