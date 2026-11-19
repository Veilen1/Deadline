extends MeshInstance3D

## Trazo visual del disparo. Se autodestruye al terminar su vida útil.

@export var width: float = 0.025
@export var color: Color = Color(1.0, 0.82, 0.25, 1.0)
@export var lifetime: float = 0.07
@export var emission_energy: float = 3.0


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Se desvanece y se libera solo.
	var tween: Tween = create_tween()
	tween.tween_property(self, "transparency", 1.0, lifetime)
	tween.tween_callback(queue_free)


func fire(from: Vector3, to: Vector3) -> void:
	var distance: float = from.distance_to(to)
	if distance <= 0.01:
		queue_free()
		return

	global_position = (from + to) * 0.5
	var direction: Vector3 = (to - from).normalized()

	# look_at falla si la dirección es paralela al up; usamos otro eje.
	var up: Vector3 = Vector3.UP
	if absf(direction.dot(up)) > 0.99:
		up = Vector3.FORWARD
	look_at(to, up)

	scale = Vector3(width, width, distance)
