extends Area3D

## Núcleo de arena: recompensa por usar la verticalidad. Se recoge una vez
## por run y desaparece.

@export var core_amount: int = 1

@onready var _visual: MeshInstance3D = $Visual

var _time: float = 0.0
var _base_y: float = 0.0
var _taken: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_y = _visual.position.y


func _process(delta: float) -> void:
	_time += delta
	rotate_y(delta * 2.0)
	_visual.position.y = _base_y + sin(_time * 3.0) * 0.08


func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	GameState.add_cores(core_amount)
	Toast.show_toast(
		"NÚCLEO DE ARENA",
		"Núcleo encontrado",
		"Recogiste un núcleo extra en la arena.",
		"+%d ◈" % core_amount,
		Color(0.95, 0.75, 0.25, 1)
	)
	AudioDirector.play_upgrade()
	queue_free()
