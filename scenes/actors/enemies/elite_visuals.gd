extends Node3D

## Da a cada élite una silueta y un tinte propios: armadura procedural encima
## del modelo riggeado compartido, sin duplicar los glb.

@export_enum("verdugo", "bastion", "alcaide") var style: String = "verdugo"
@export var tint_color: Color = Color(1.0, 0.78, 0.28, 1.0)
@export_range(0.0, 1.0) var tint_amount: float = 0.4
@export var tint_emission: float = 0.45
@export var armor_color: Color = Color(1.0, 0.72, 0.2, 1.0)
@export var glow_color: Color = Color(1.0, 0.55, 0.15, 1.0)


func _ready() -> void:
	_tint_model()
	match style:
		"bastion":
			_build_bastion()
		"alcaide":
			_build_alcaide()
		_:
			_build_verdugo()


func _tint_model() -> void:
	var model: Node3D = get_parent().get_node_or_null("Model") as Node3D
	if model == null:
		return
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var base: Material = mesh_instance.get_active_material(surface)
			if not base is StandardMaterial3D:
				continue
			var tinted: StandardMaterial3D = (base as StandardMaterial3D).duplicate()
			tinted.albedo_color = tinted.albedo_color.lerp(tint_color, tint_amount)
			tinted.emission_enabled = true
			tinted.emission = tint_color
			tinted.emission_energy_multiplier = tint_emission
			mesh_instance.set_surface_override_material(surface, tinted)


func _build_verdugo() -> void:
	# Verdugo: cuernos, hombreras con púas y visor encendido.
	_add_cone(Vector3(0.09, 0.34, 0.09), Vector3(-0.2, 1.03, -0.02), Vector3(-8, 0, 28), armor_color)
	_add_cone(Vector3(0.09, 0.34, 0.09), Vector3(0.2, 1.03, -0.02), Vector3(-8, 0, -28), armor_color)
	_add_box(Vector3(0.32, 0.16, 0.42), Vector3(-0.46, 0.47, 0.0), Vector3(0, 0, 12), armor_color)
	_add_box(Vector3(0.32, 0.16, 0.42), Vector3(0.46, 0.47, 0.0), Vector3(0, 0, -12), armor_color)
	_add_cone(Vector3(0.07, 0.26, 0.07), Vector3(-0.52, 0.62, 0.0), Vector3(0, 0, 55), glow_color)
	_add_cone(Vector3(0.07, 0.26, 0.07), Vector3(0.52, 0.62, 0.0), Vector3(0, 0, -55), glow_color)
	_add_box(Vector3(0.62, 0.3, 0.1), Vector3(0, 0.3, -0.27), Vector3.ZERO, armor_color)
	_add_box(Vector3(0.3, 0.05, 0.04), Vector3(0, 0.72, -0.245), Vector3.ZERO, glow_color, true)


func _build_bastion() -> void:
	# Bastión: hombreras enormes, cresta alta y emblema de escudo.
	_add_box(Vector3(0.46, 0.22, 0.52), Vector3(-0.52, 0.51, 0.0), Vector3(0, 0, 16), armor_color)
	_add_box(Vector3(0.46, 0.22, 0.52), Vector3(0.52, 0.51, 0.0), Vector3(0, 0, -16), armor_color)
	_add_box(Vector3(0.5, 0.12, 0.56), Vector3(-0.5, 0.66, 0.0), Vector3(0, 0, 10), glow_color, true)
	_add_box(Vector3(0.5, 0.12, 0.56), Vector3(0.5, 0.66, 0.0), Vector3(0, 0, -10), glow_color, true)
	_add_box(Vector3(0.07, 0.44, 0.26), Vector3(0, 1.0, 0.02), Vector3(0, 0, 0), armor_color)
	_add_cone(Vector3(0.11, 0.24, 0.11), Vector3(0, 1.28, 0.02), Vector3.ZERO, glow_color)
	_add_box(Vector3(0.66, 0.42, 0.12), Vector3(0, 0.3, -0.28), Vector3.ZERO, armor_color)
	_add_cylinder(0.13, 0.13, 0.05, Vector3(0, 0.32, -0.35), Vector3(90, 0, 0), glow_color, true)
	_add_box(Vector3(0.6, 0.16, 0.06), Vector3(0, 0.02, 0.26), Vector3(0, 0, 0), glow_color, true)


func _build_alcaide() -> void:
	# Alcaide: ala de sombrero ancha, bandolera y tercer ojo encendido.
	_add_cylinder(0.44, 0.44, 0.035, Vector3(0, 0.94, 0.0), Vector3.ZERO, armor_color)
	_add_cylinder(0.16, 0.19, 0.2, Vector3(0, 1.04, 0.0), Vector3.ZERO, armor_color)
	_add_box(Vector3(0.16, 0.72, 0.07), Vector3(0, 0.3, -0.27), Vector3(0, 0, 32), armor_color)
	_add_box(Vector3(0.16, 0.72, 0.07), Vector3(0, 0.3, 0.24), Vector3(0, 0, -32), armor_color)
	_add_sphere(0.05, Vector3(0.19, 0.42, -0.32), glow_color, true)
	_add_sphere(0.045, Vector3(0, 0.76, -0.235), glow_color, true)
	_add_box(Vector3(0.34, 0.06, 0.05), Vector3(0, 0.9, 0.2), Vector3.ZERO, glow_color, true)


func _add_box(
	size: Vector3,
	position: Vector3,
	rotation_degrees: Vector3,
	color: Color,
	unshaded: bool = false
) -> void:
	var box := BoxMesh.new()
	box.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = box
	instance.material_override = _armor_material(color, unshaded)
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	add_child(instance)


func _add_cone(
	size: Vector3,
	position: Vector3,
	rotation_degrees: Vector3,
	color: Color,
	unshaded: bool = false
) -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = size.x
	cone.height = size.y
	var instance := MeshInstance3D.new()
	instance.mesh = cone
	instance.material_override = _armor_material(color, unshaded)
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	add_child(instance)


func _add_cylinder(
	top_radius: float,
	bottom_radius: float,
	height: float,
	position: Vector3,
	rotation_degrees: Vector3,
	color: Color,
	unshaded: bool = false
) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top_radius
	cylinder.bottom_radius = bottom_radius
	cylinder.height = height
	cylinder.radial_segments = 20
	var instance := MeshInstance3D.new()
	instance.mesh = cylinder
	instance.material_override = _armor_material(color, unshaded)
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	add_child(instance)


func _add_sphere(radius: float, position: Vector3, color: Color, unshaded: bool = false) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	var instance := MeshInstance3D.new()
	instance.mesh = sphere
	instance.material_override = _armor_material(color, unshaded)
	instance.position = position
	add_child(instance)


func _armor_material(color: Color, unshaded: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.4
	else:
		material.metallic = 0.75
		material.roughness = 0.32
	return material
