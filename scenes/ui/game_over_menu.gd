extends Control

const HUB_SCENE: String = "res://scenes/ui/hub.tscn"

@onready var reason_label: Label = $CenterContainer/Menu/ReasonLabel
@onready var penalty_label: Label = $CenterContainer/Menu/PenaltyLabel
@onready var money_label: Label = $CenterContainer/Menu/MoneyLabel
@onready var grade_label: Label = $CenterContainer/Menu/GradeLabel
@onready var retry_button: Button = $CenterContainer/Menu/RetryButton
@onready var hub_button: Button = $CenterContainer/Menu/HubButton


func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_on_retry_pressed)
	hub_button.pressed.connect(_on_hub_pressed)


func show_result(reason: String, money: int) -> void:
	Diagnostics.mark("game_over_show", {"reason": reason, "money": money})
	reason_label.text = _reason_text(reason)
	money_label.text = "Plata acumulada: $%d" % money
	grade_label.text = "Grado %s · +%d núcleos" % [
		GameState.last_grade,
		GameState.last_grade_cores,
	]
	grade_label.add_theme_color_override("font_color", _grade_color(GameState.last_grade))

	if reason == "death" and GameState.last_death_penalty > 0:
		penalty_label.text = "Penalización (%d%%): -$%d" % [
			int(round(GameState.death_penalty * 100.0)), GameState.last_death_penalty
		]
		penalty_label.show()
	else:
		penalty_label.hide()

	# El cursor se libera antes de mostrar el menú para que el primer click
	# no se pierda mientras Windows todavía lo mantiene oculto.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	show()
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)

	# Espera un frame para que el layout calcule la posición del botón.
	await get_tree().process_frame
	Diagnostics.mark("game_over_layout", {
		"rect": str(retry_button.get_global_rect()),
		"focused": get_window().has_focus(),
	})
	_warp_cursor_to(retry_button)
	retry_button.grab_focus()
	Diagnostics.mark("game_over_ready", {"mouse": str(get_viewport().get_mouse_position())})


func _warp_cursor_to(control: Control) -> void:
	# warp_mouse fuerza a Windows a mostrar el cursor en el acto al salir
	# de MOUSE_MODE_CAPTURED, sin esperar a que el jugador mueva el mouse.
	if DisplayServer.get_name() == "headless" or control == null:
		return
	Input.warp_mouse(control.get_global_rect().get_center())


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


func _grade_color(grade: String) -> Color:
	match grade:
		"S":
			return Color(1.0, 0.82, 0.3, 1)
		"A":
			return Color(0.3, 0.9, 0.85, 1)
		"B":
			return Color(0.85, 0.9, 1.0, 1)
		_:
			return Color(0.65, 0.72, 0.82, 1)


func _on_retry_pressed() -> void:
	Diagnostics.mark("retry_pressed")
	get_tree().paused = false
	Transitions.reload_current_scene()


func _on_hub_pressed() -> void:
	Diagnostics.mark("hub_pressed")
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Transitions.change_scene_to_file(HUB_SCENE)