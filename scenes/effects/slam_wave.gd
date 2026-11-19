extends Node3D

## Onda de choque al aterrizar el élite.

@export var color: Color = Color(1.0, 0.4, 0.15, 1.0)
@export var emission_energy: float = 4.0
@export var duration: float = 0.35


func start(radius: float) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	torus.rings = 64
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = _make_material()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

	scale = Vector3(0.2, 1.0, 0.2)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(radius, 1.0, radius), duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "transparency", 1.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _make_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	return material
