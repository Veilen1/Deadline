extends Node3D

## Aviso de aparición: calavera roja, anillo y haz de luz en el punto donde
## van a salir los enemigos. Dura lo que indique el spawner.

@export var lifetime: float = 2.0
@export var enemy_label: String = "BÁSICO"
@export var accent_color: Color = Color(1.0, 0.2, 0.12, 1.0)
@export var is_elite: bool = false

@onready var _label: Label3D = $Label
@onready var _name_label: Label3D = $NameLabel
@onready var _ring: MeshInstance3D = $Ring
@onready var _beam: MeshInstance3D = $Beam
@onready var _light: OmniLight3D = $Light

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
	scale = Vector3.ONE * (1.3 if is_elite else 1.0)
	_name_label.text = enemy_label
	_apply_accent()
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


func _apply_accent() -> void:
	_label.modulate = accent_color
	_name_label.modulate = accent_color
	_light.light_color = accent_color

	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.albedo_color = accent_color
	ring_material.emission_enabled = true
	ring_material.emission = accent_color
	ring_material.emission_energy_multiplier = 3.0
	_ring.material_override = ring_material

	var beam_color: Color = accent_color
	beam_color.a = 0.14
	var beam_material := StandardMaterial3D.new()
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.albedo_color = beam_color
	beam_material.emission_enabled = true
	beam_material.emission = accent_color
	beam_material.emission_energy_multiplier = 1.2
	_beam.material_override = beam_material
