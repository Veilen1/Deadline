extends Node3D

## Viewmodel de armas en primera persona. Cambia la skin según el arma y
## anima el cambio bajando/rotando el arma. También muestra un muzzle flash.

const MODEL_AK: PackedScene = preload("res://assets/models/weapons/ak47.glb")
const MODEL_PISTOL: PackedScene = preload("res://assets/models/weapons/pistol.glb")
const MODEL_SMG: PackedScene = preload("res://assets/models/weapons/smg.glb")
const MODEL_SHOTGUN: PackedScene = preload("res://assets/models/weapons/shotgun.glb")

@export var switch_drop: float = 0.24
@export var switch_tilt_deg: float = -38.0
@export var switch_out_time: float = 0.1
@export var switch_in_time: float = 0.18

var _current_id: String = ""
var _base_position: Vector3
var _base_rotation: Vector3
var _muzzle_position: Vector3 = Vector3(0, 0.02, -0.36)
var _model_muzzle: Node3D
var _flash: MeshInstance3D
var _tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	_base_position = position
	_base_rotation = rotation


func setup(weapon_id: String) -> void:
	_current_id = weapon_id
	_build(weapon_id)
	position = _base_position
	rotation = _base_rotation


func switch_to(weapon_id: String) -> void:
	if weapon_id == _current_id:
		return

	_current_id = weapon_id
	if _tween != null and _tween.is_valid():
		_tween.kill()

	var down_position: Vector3 = _base_position + Vector3(0.0, -switch_drop, 0.0)
	var down_rotation_x: float = _base_rotation.x + deg_to_rad(switch_tilt_deg)

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", down_position, switch_out_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "rotation:x", down_rotation_x, switch_out_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.set_parallel(false)
	_tween.tween_callback(func() -> void: _build(weapon_id))
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", _base_position, switch_in_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation:x", _base_rotation.x, switch_in_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func flash() -> void:
	if not is_instance_valid(_flash):
		return

	_flash.visible = true
	_flash.scale = Vector3.ONE * randf_range(0.8, 1.3)
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "scale", Vector3.ONE * 0.1, 0.06)
	_flash_tween.tween_callback(_flash.hide)


func _build(weapon_id: String) -> void:
	# Los meshes del arma anterior se liberan al instante para no superponerse.
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	for child in get_children():
		child.free()
	_flash = null
	_model_muzzle = null

	match weapon_id:
		"pistol":
			_muzzle_position = Vector3(0, 0.02, -0.235)
			_build_model(MODEL_PISTOL, 1.2)
		"basic_rifle":
			_muzzle_position = Vector3(0, 0.015, -0.36)
			_build_model(MODEL_AK, 0.55)
		"smg":
			_muzzle_position = Vector3(0, 0.015, -0.25)
			_build_model(MODEL_SMG, 0.7)
		"shotgun":
			_muzzle_position = Vector3(0, 0.025, -0.44)
			_build_model(MODEL_SHOTGUN, 0.55)
		_:
			_muzzle_position = Vector3(0, 0.015, -0.36)
			_build_rifle()

	_build_flash()
	_attach_flash_to_muzzle()


func _build_model(scene: PackedScene, model_scale: float) -> void:
	var model: Node3D = scene.instantiate() as Node3D
	if model == null:
		return
	add_child(model)
	model.scale = Vector3.ONE * model_scale
	_disable_shadows(model)
	_hide_forearms(model)
	if _current_id == "pistol":
		_hide_pistol_hands(model)
	_model_muzzle = _find_muzzle(model)


func _hide_pistol_hands(node: Node) -> void:
	# Las manos del prototipo tapaban la pistola; se ocultan hasta la pasada de brazos.
	if node is Node3D:
		var node_name: String = node.name
		if (
			node_name.begins_with("Pistol_Hand")
			or node_name.begins_with("Pistol_Finger")
			or node_name.begins_with("Pistol_Thumb")
		):
			(node as Node3D).visible = false
	for child in node.get_children():
		_hide_pistol_hands(child)


func _hide_forearms(node: Node) -> void:
	# Los antebrazos largos ocupan demasiada pantalla; por ahora quedan las manos.
	if node is Node3D:
		var node_name: String = node.name
		if (
			node_name.begins_with("Arm_Forearm")
			or node_name.begins_with("Arm_WristBand")
			or node_name.begins_with("Pistol_Arm")
			or node_name.begins_with("Pistol_Band")
		):
			(node as Node3D).visible = false
	for child in node.get_children():
		_hide_forearms(child)


func _find_muzzle(node: Node) -> Node3D:
	for child in node.get_children():
		if child is Node3D and child.name.begins_with("Muzzle"):
			return child as Node3D
		var found: Node3D = _find_muzzle(child)
		if found != null:
			return found
	return null


func _disable_shadows(node: Node) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows(child)


func _attach_flash_to_muzzle() -> void:
	if _flash == null or _model_muzzle == null:
		return
	_flash.get_parent().remove_child(_flash)
	_model_muzzle.add_child(_flash)
	_flash.position = Vector3.ZERO


func _build_pistol() -> void:
	# Fallback de caja si el modelo glTF no está disponible.
	_add_box(Vector3(0.055, 0.17, 0.055), Vector3(0, 0.02, -0.10), Color(0.14, 0.15, 0.18))
	_add_box(Vector3(0.022, 0.022, 0.05), Vector3(0, 0.02, -0.20), Color(0.22, 0.23, 0.26))
	_add_box(Vector3(0.045, 0.10, 0.05), Vector3(0, 0.0, -0.03), Color(0.08, 0.09, 0.11))
	_add_box(Vector3(0.045, 0.06, 0.12), Vector3(0, -0.07, 0.035), Color(0.06, 0.07, 0.09),
		0.0, Vector3(-14, 0, 0))


func _build_rifle() -> void:
	_add_box(Vector3(0.09, 0.09, 0.3), Vector3(0, 0, 0.02), Color(0.12, 0.13, 0.17))
	_add_box(Vector3(0.04, 0.04, 0.24), Vector3(0, 0.015, -0.23), Color(0.22, 0.22, 0.26))
	_add_box(Vector3(0.06, 0.16, 0.08), Vector3(0, -0.1, 0.08), Color(0.08, 0.08, 0.1))
	_add_box(Vector3(0.06, 0.09, 0.12), Vector3(0, -0.01, 0.17), Color(0.1, 0.1, 0.13))
	_add_box(Vector3(0.02, 0.02, 0.1), Vector3(0, 0.06, -0.08), Color(0.95, 0.75, 0.25), 2.2)


func _build_smg() -> void:
	_add_box(Vector3(0.1, 0.1, 0.22), Vector3(0, 0, 0.03), Color(0.07, 0.16, 0.18))
	_add_box(Vector3(0.04, 0.04, 0.14), Vector3(0, 0.015, -0.17), Color(0.18, 0.22, 0.24))
	_add_box(Vector3(0.06, 0.14, 0.08), Vector3(0, -0.1, 0.06), Color(0.05, 0.1, 0.12))
	_add_box(Vector3(0.05, 0.18, 0.07), Vector3(0, -0.15, -0.03), Color(0.06, 0.12, 0.14))
	_add_box(Vector3(0.02, 0.02, 0.12), Vector3(0, 0.065, -0.02), Color(0.3, 0.85, 0.8), 2.5)


func _build_shotgun() -> void:
	_add_box(Vector3(0.1, 0.09, 0.26), Vector3(0, 0, 0.03), Color(0.2, 0.12, 0.06))
	_add_box(Vector3(0.08, 0.08, 0.36), Vector3(0, 0.025, -0.25), Color(0.18, 0.18, 0.2))
	_add_box(Vector3(0.09, 0.06, 0.14), Vector3(0, -0.04, -0.22), Color(0.14, 0.08, 0.04))
	_add_box(Vector3(0.07, 0.11, 0.16), Vector3(0, -0.02, 0.18), Color(0.14, 0.08, 0.04))
	_add_box(Vector3(0.02, 0.02, 0.12), Vector3(0, 0.07, -0.06), Color(1.0, 0.55, 0.2), 2.2)


func _add_box(
	size: Vector3,
	offset: Vector3,
	color: Color,
	emission_energy: float = 0.0,
	rotation: Vector3 = Vector3.ZERO
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	material.metallic = 0.35
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy

	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	instance.rotation = rotation
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _build_flash() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.85, 0.35, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.75, 0.2, 1.0)
	material.emission_energy_multiplier = 5.0

	_flash = MeshInstance3D.new()
	_flash.mesh = mesh
	_flash.material_override = material
	_flash.position = _muzzle_position
	_flash.visible = false
	_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_flash)
