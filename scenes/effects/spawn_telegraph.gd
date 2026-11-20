extends Node3D

## Aviso de aparición: calavera roja, anillo y haz de luz en el punto donde
## van a salir los enemigos. Dura lo que indique el spawner.

@export var lifetime: float = 2.0

@onready var _label: Label3D = $Label
@onready var _ring: MeshInstance3D = $Ring
@onready var _beam: MeshInstance3D = $Beam

var _elapsed: float = 0.0
var _base_label_y: float = 0.0
var _base_ring_scale: Vector3 = Vector3.ONE
var _tween: Tween


func _ready() -> void:
	_base_label_y = _label.position.y
	_base_ring_scale = _ring.scale


func start(duration: float) -> void:
	lifetime = duration
	_elapsed = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_label.modulate.a = 0.0
	_beam.transparency = 0.0
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 1.0, 0.12)
	_tween.tween_interval(maxf(lifetime - 0.4, 0.1))
	_tween.tween_property(_label, "modulate:a", 0.0, 0.25)
	_tween.parallel().tween_property(_beam, "transparency", 1.0, 0.25)
	_tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_elapsed += delta
	var pulse: float = 1.0 + sin(_elapsed * 9.0) * 0.08
	_ring.scale = Vector3(
		_base_ring_scale.x * pulse, _base_ring_scale.y, _base_ring_scale.z * pulse
	)
	_label.position.y = _base_label_y + sin(_elapsed * 4.0) * 0.07
