extends Node3D

## Diana de aviso del salto del élite. Marca el radio de daño en el piso y
## muestra el tiempo restante con un anillo que se cierra.

@export var ring_color: Color = Color(1.0, 0.28, 0.12, 1.0)
@export var emission_energy: float = 2.5
@export var disc_alpha: float = 0.10
@export var tick_count: int = 8

var _radius: float = 1.0
var _shrink_ring: MeshInstance3D
var _ticks: Node3D


func start(radius: float, duration: float) -> void:
	_radius = maxf(radius, 0.1)
	_build()
	_animate(duration)


func _build() -> void:
	_add_disc()
	_add_ring(_radius, maxf(_radius * 0.02, 0.04))
	_add_ring(_radius * 0.62, maxf(_radius * 0.015, 0.03))
	_add_center_dot()
	_add_ticks()
	_shrink_ring = _add_ring(_radius, maxf(_radius * 0.015, 0.03))


func _add_disc() -> void:
	var instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = _radius
	cylinder.bottom_radius = _radius
	cylinder.height = 0.004
	cylinder.radial_segments = 64
	instance.mesh = cylinder
	instance.material_override = _make_material(disc_alpha)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _add_ring(ring_radius: float, thickness: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(ring_radius - thickness, 0.01)
	torus.outer_radius = ring_radius
	torus.rings = 64
	torus.ring_segments = 8
	instance.mesh = torus
	instance.material_override = _make_material(0.9)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance


func _add_center_dot() -> void:
	var instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = maxf(_radius * 0.06, 0.08)
	cylinder.bottom_radius = maxf(_radius * 0.06, 0.08)
	cylinder.height = 0.006
	cylinder.radial_segments = 32
	instance.mesh = cylinder
	instance.material_override = _make_material(1.0)
	instance.position.y = 0.004
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _add_ticks() -> void:
	_ticks = Node3D.new()
	add_child(_ticks)

	for index in tick_count:
		var angle: float = TAU * float(index) / float(tick_count)
		var instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(maxf(_radius * 0.16, 0.2), 0.006, 0.05)
		instance.mesh = box
		instance.material_override = _make_material(0.85)
		instance.position = Vector3(cos(angle), 0.0, sin(angle)) * (_radius * 0.87)
		instance.rotation.y = -angle
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ticks.add_child(instance)


func _make_material(alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(ring_color.r, ring_color.g, ring_color.b, alpha)
	material.emission_enabled = true
	material.emission = ring_color
	material.emission_energy_multiplier = emission_energy
	return material


func _animate(duration: float) -> void:
	var safe_duration: float = maxf(duration, 0.1)

	# Pulso suave de toda la diana.
	var pulse := create_tween().set_loops()
	pulse.tween_property(self, "scale", Vector3(1.03, 1.0, 1.03), 0.22) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(self, "scale", Vector3(0.98, 1.0, 0.98), 0.22) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# El anillo interior se cierra marcando cuánto falta para el impacto.
	var shrink := create_tween()
	shrink.tween_property(_shrink_ring, "scale", Vector3(0.05, 1.0, 0.05), safe_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Giro lento de las marcas.
	var spin := create_tween()
	spin.tween_property(_ticks, "rotation:y", TAU, safe_duration).set_trans(Tween.TRANS_LINEAR)
