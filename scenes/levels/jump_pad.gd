extends Area3D

## Jump pad: impulsa al jugador hacia arriba. La dirección horizontal es el
## -Z local del pad, así se puede orientar en cada arena.

@export var launch_speed: float = 12.5
@export var forward_boost: float = 2.0
@export var cooldown: float = 0.5

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _audio: AudioStreamPlayer3D = $Audio

var _cooldown_timer: float = 0.0
var _pulse: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
	_pulse += delta
	if _mesh != null:
		var pulse_scale: float = 1.0 + sin(_pulse * 5.0) * 0.04
		_mesh.scale = Vector3(pulse_scale, 1.0, pulse_scale)


func _on_body_entered(body: Node) -> void:
	if _cooldown_timer > 0.0 or not body.is_in_group("player"):
		return
	_cooldown_timer = cooldown

	var forward: Vector3 = -global_basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	body.call(
		"launch", Vector3(forward.x * forward_boost, launch_speed, forward.z * forward_boost)
	)
	if _audio != null:
		_audio.pitch_scale = randf_range(0.95, 1.08)
		_audio.play()
