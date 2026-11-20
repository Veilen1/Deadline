extends Control

const HUB_SCENE: String = "res://scenes/ui/hub.tscn"

@onready var reason_label: Label = $CenterContainer/Menu/ReasonLabel
@onready var penalty_label: Label = $CenterContainer/Menu/PenaltyLabel
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

	if reason == "death" and GameState.last_death_penalty > 0:
		penalty_label.text = "Penalización (%d%%): -$%d" % [
			int(round(GameState.death_penalty * 100.0)), GameState.last_death_penalty
		]
		penalty_label.show()
	else:
		penalty_label.hide()

	show()
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
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
	Transitions.reload_current_scene()


func _on_hub_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Transitions.change_scene_to_file(HUB_SCENE)