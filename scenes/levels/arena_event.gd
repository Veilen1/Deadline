extends Node3D

## Evento de arena destructible. El tipo lo elige la zona al azar de su pool
## (ver ArenaEventRegistry). Según el tipo pulsa daño, ralentiza, dispara,
## suelta minas, tira del jugador o cura enemigos. Al destruirlo entrega núcleos.

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/effects/enemy_projectile.tscn")
const SLAM_WAVE_SCENE: PackedScene = preload("res://scenes/effects/slam_wave.tscn")
const MINE_SCENE: PackedScene = preload("res://scenes/effects/arena_mine.tscn")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/effects/damage_number.tscn")
const TURRET_MODEL: PackedScene = preload("res://assets/models/events/turret.glb")

@export var event_kind: String = "pulse"
@export var auto_start: bool = false
@export var title: String = "Reactor inestable"
@export var description: String = "Pulsa daño en el área."
@export var max_health: float = 150.0
@export var core_reward: int = 2
@export var radius: float = 6.0

@export_group("Pulse")
@export var pulse_damage: float = 8.0
@export var pulse_interval: float = 3.0

@export_group("Slow")
@export var slow_multiplier: float = 0.6
@export var slow_duration: float = 0.8
@export var slow_interval: float = 0.6

@export_group("Turret")
@export var projectile_damage: float = 14.0
@export var projectile_interval: float = 1.5
@export var projectile_speed: float = 20.0

@export_group("Mines")
@export var mine_interval: float = 3.4
@export var mine_count: int = 2
@export var mine_damage: float = 20.0
@export var mine_explosion_radius: float = 3.4

@export_group("Pull")
@export var pull_interval: float = 2.6
@export var pull_force: float = 5.5

@export_group("Heal")
@export var heal_interval: float = 2.4
@export var heal_amount: float = 22.0

@onready var _core: MeshInstance3D = $Core
@onready var _ring: MeshInstance3D = $Ring
@onready var _label: Label3D = $Label
@onready var _light: OmniLight3D = $Light

var current_health: float
var _timer: float = 0.0
var _time: float = 0.0
var _ring_base_scale: Vector3 = Vector3.ONE
var _started: bool = false
var _turret_model: Node3D
var _altar: Node3D
var _label_base: float = 3.1
var _glow_materials: Array[StandardMaterial3D] = []
var _spin_nodes: Array[Node3D] = []


func _ready() -> void:
	add_to_group("arena_events")
	_ring_base_scale = _ring.scale
	# Las zonas llaman a start() para elegir el tipo; auto_start queda para
	# instancias sueltas o pruebas.
	if auto_start:
		start(event_kind)


func start(kind: String = "") -> void:
	# Aplica el catálogo y arranca el evento una sola vez.
	if _started:
		return
	_started = true

	if not kind.is_empty():
		event_kind = kind
	_apply_registry_data()
	_apply_scaling()
	_timer = _initial_interval()
	_apply_style()
	_update_label()
	_label_base = 1.75 if event_kind == "turret" else 3.1
	if event_kind == "turret":
		_spawn_turret()
	else:
		_build_altar()
	Toast.show_toast(
		"EVENTO DE ARENA",
		title,
		description,
		"Destruilo para +%d ◈" % core_reward,
		_accent()
	)
	AudioDirector.play_event_spawn(global_position + Vector3.UP * 1.5)


func _apply_registry_data() -> void:
	var data: Dictionary = ArenaEventRegistry.get_data(event_kind)
	if data.is_empty():
		return

	title = str(data.get("title", title))
	description = str(data.get("description", description))
	max_health = float(data.get("health", max_health))
	core_reward = int(data.get("reward", core_reward))
	radius = float(data.get("radius", radius))
	pulse_damage = float(data.get("pulse_damage", pulse_damage))
	pulse_interval = float(data.get("pulse_interval", pulse_interval))
	slow_multiplier = float(data.get("slow_multiplier", slow_multiplier))
	slow_duration = float(data.get("slow_duration", slow_duration))
	slow_interval = float(data.get("slow_interval", slow_interval))
	projectile_damage = float(data.get("projectile_damage", projectile_damage))
	projectile_interval = float(data.get("projectile_interval", projectile_interval))
	projectile_speed = float(data.get("projectile_speed", projectile_speed))
	mine_interval = float(data.get("mine_interval", mine_interval))
	mine_count = int(data.get("mine_count", mine_count))
	mine_damage = float(data.get("mine_damage", mine_damage))
	mine_explosion_radius = float(data.get("mine_explosion_radius", mine_explosion_radius))
	pull_interval = float(data.get("pull_interval", pull_interval))
	pull_force = float(data.get("pull_force", pull_force))
	heal_interval = float(data.get("heal_interval", heal_interval))
	heal_amount = float(data.get("heal_amount", heal_amount))


func _apply_scaling() -> void:
	max_health *= (
		GameState.cycle_enemy_health_mult() * GameState.contract_modifier("enemy_health", 1.0)
	)
	current_health = max_health
	var damage_mult: float = _enemy_damage_mult()
	pulse_damage *= damage_mult
	projectile_damage *= damage_mult
	mine_damage *= damage_mult


func _physics_process(delta: float) -> void:
	if not _started or not GameState.is_run_active:
		return

	_time += delta
	_timer -= delta
	_update_visuals(delta)
	_update_turret_aim()

	if _timer <= 0.0:
		_timer = _interval()
		_trigger()


func _spawn_turret() -> void:
	# La torreta reemplaza al reactor: base, cabezal y cañón.
	_turret_model = TURRET_MODEL.instantiate() as Node3D
	if _turret_model == null:
		return
	add_child(_turret_model)
	_turret_model.position = Vector3.ZERO
	_turret_model.scale = Vector3.ONE * 1.45
	_core.visible = false
	_ring.visible = false


# --- Altares: cada evento tiene su propia silueta y su propia colisión. ---

func _build_altar() -> void:
	_core.hide()
	_ring.hide()
	_altar = Node3D.new()
	_altar.name = "Altar"
	add_child(_altar)

	var accent: Color = _accent()
	match event_kind:
		"slow":
			_build_ice(accent)
		"mines":
			_build_mines(accent)
		"pull":
			_build_pull(accent)
		"heal":
			_build_heal(accent)
		_:
			_build_reactor(accent)

	_setup_hitbox()
	_label.position.y = _label_base


func _build_reactor(accent: Color) -> void:
	var stone := _stone_material()
	var dark := _metal_material(Color(0.18, 0.21, 0.28))
	var glow := _glow_material(accent)

	_add_cylinder(0.95, 1.05, 0.3, Vector3(0, 0.15, 0), stone)
	_add_cylinder(0.42, 0.5, 1.8, Vector3(0, 1.2, 0), glow, 12)
	for height in [0.52, 1.2, 1.88]:
		_add_torus(0.58, 0.7, Vector3(0, height, 0), Vector3.ZERO, glow)
	for index in 4:
		var angle: float = float(index) * PI * 0.5
		_add_box(
			Vector3(0.14, 1.5, 0.34),
			Vector3(cos(angle) * 0.68, 1.15, sin(angle) * 0.68),
			dark,
			Vector3(0, rad_to_deg(angle), 0)
		)
	_add_cone(0.32, 0.5, Vector3(0, 2.3, 0), glow)
	_label_base = 2.9


func _build_ice(accent: Color) -> void:
	var stone := _stone_material()
	var dark := _metal_material(Color(0.16, 0.22, 0.3))
	var glow := _glow_material(accent, 1.9)

	_add_cylinder(0.9, 0.98, 0.26, Vector3(0, 0.13, 0), stone)
	_add_cylinder(0.48, 0.56, 0.5, Vector3(0, 0.5, 0), dark)
	_add_cone(0.6, 1.2, Vector3(0, 1.65, 0), glow, 6)
	_add_cone(0.6, 1.0, Vector3(0, 0.55, 0), glow, 6, Vector3(180, 0, 0))
	_add_spin_torus(0.7, 0.82, Vector3(0, 1.2, 0), Vector3(90, 0, 18), glow)
	_add_spin_torus(0.94, 1.04, Vector3(0, 1.2, 0), Vector3(74, 0, -24), glow)
	_label_base = 2.7


func _build_mines(accent: Color) -> void:
	var stone := _stone_material()
	var dark := _metal_material(Color(0.26, 0.2, 0.16))
	var glow := _glow_material(accent, 2.3)

	_add_cylinder(1.0, 1.06, 0.4, Vector3(0, 0.2, 0), stone)
	_add_cylinder(0.72, 0.8, 1.0, Vector3(0, 0.9, 0), dark)
	_add_torus(0.8, 0.9, Vector3(0, 0.9, 0), Vector3.ZERO, glow)
	_add_cylinder(0.8, 0.4, 0.5, Vector3(0, 1.65, 0), stone)
	_add_cylinder(0.22, 0.26, 1.2, Vector3(0.52, 1.75, 0), dark, 10)
	_add_cone(0.32, 0.35, Vector3(0.52, 2.42, 0), glow)
	_add_box(Vector3(0.5, 0.3, 0.6), Vector3(0, 0.45, -0.95), dark)
	_add_box(Vector3(0.85, 0.06, 0.5), Vector3(0, 0.3, -1.18), glow)
	_label_base = 2.9


func _build_pull(accent: Color) -> void:
	var dark := _metal_material(Color(0.14, 0.12, 0.2))
	var glow := _glow_material(accent, 2.1)

	_add_cylinder(0.88, 0.96, 0.2, Vector3(0, 0.1, 0), dark, 20)
	_add_torus(0.55, 0.64, Vector3(0, 0.9, 0), Vector3.ZERO, dark)
	for index in 3:
		var angle: float = float(index) * TAU / 3.0
		_add_cylinder(
			0.07,
			0.1,
			0.95,
			Vector3(cos(angle) * 0.55, 0.55, sin(angle) * 0.55),
			dark,
			8
		)
	_add_cone(0.55, 0.8, Vector3(0, 1.9, 0), glow, 4)
	_add_cone(0.55, 0.7, Vector3(0, 1.15, 0), glow, 4, Vector3(180, 0, 0))
	_add_spin_torus(0.7, 0.82, Vector3(0, 1.5, 0), Vector3(90, 0, 0), glow)
	_add_spin_torus(0.92, 1.04, Vector3(0, 1.5, 0), Vector3(66, 0, 34), glow)
	_label_base = 2.7


func _build_heal(accent: Color) -> void:
	var stone := _stone_material()
	var dark := _metal_material(Color(0.16, 0.26, 0.2))
	var glow := _glow_material(accent, 2.0)

	_add_cylinder(0.85, 0.92, 0.28, Vector3(0, 0.14, 0), dark)
	_add_cylinder(0.22, 0.3, 0.8, Vector3(0, 0.65, 0), stone, 10)
	_add_sphere(0.5, Vector3(0, 1.35, 0), glow)
	_add_box(Vector3(0.14, 0.9, 0.14), Vector3(0, 1.35, 0), glow)
	_add_box(Vector3(0.9, 0.14, 0.14), Vector3(0, 1.35, 0), glow)
	_add_spin_torus(0.7, 0.8, Vector3(0, 1.35, 0), Vector3(90, 0, 0), glow)
	_add_spin_torus(0.92, 1.02, Vector3(0, 1.35, 0), Vector3(72, 0, 26), glow)
	_label_base = 2.6


func _setup_hitbox() -> void:
	var hitbox: Area3D = $TorsoHitbox
	for child in hitbox.get_children():
		child.free()
	hitbox.position = Vector3.ZERO

	match event_kind:
		"slow":
			_add_hitbox_cylinder(1.0, 0.3, Vector3(0, 0.15, 0))
			_add_hitbox_cylinder(0.6, 2.2, Vector3(0, 1.2, 0))
		"mines":
			_add_hitbox_cylinder(1.06, 0.42, Vector3(0, 0.21, 0))
			_add_hitbox_cylinder(0.8, 1.9, Vector3(0, 1.0, 0))
			_add_hitbox_cylinder(0.3, 1.4, Vector3(0.52, 1.8, 0))
			_add_hitbox_box(Vector3(0.55, 0.35, 0.62), Vector3(0, 0.45, -0.95))
		"pull":
			_add_hitbox_cylinder(0.96, 0.24, Vector3(0, 0.12, 0))
			_add_hitbox_sphere(0.78, Vector3(0, 1.5, 0))
		"heal":
			_add_hitbox_cylinder(0.92, 0.3, Vector3(0, 0.15, 0))
			_add_hitbox_cylinder(0.3, 0.9, Vector3(0, 0.65, 0))
			_add_hitbox_sphere(0.8, Vector3(0, 1.35, 0))
		_:
			_add_hitbox_cylinder(1.05, 0.32, Vector3(0, 0.16, 0))
			_add_hitbox_cylinder(0.72, 2.6, Vector3(0, 1.3, 0))


func _add_hitbox_cylinder(radius: float, height: float, position: Vector3) -> void:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = position
	$TorsoHitbox.add_child(collision)


func _add_hitbox_sphere(radius: float, position: Vector3) -> void:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = position
	$TorsoHitbox.add_child(collision)


func _add_hitbox_box(size: Vector3, position: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = position
	$TorsoHitbox.add_child(collision)


func _stone_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.38, 0.47, 1)
	material.roughness = 0.82
	return material


func _metal_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.65
	material.roughness = 0.38
	return material


func _glow_material(color: Color, energy: float = 2.4) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	_glow_materials.append(material)
	return material


func _add_mesh(
	mesh: Mesh,
	position: Vector3,
	material: Material,
	rotation_degrees: Vector3 = Vector3.ZERO,
	parent: Node3D = null
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	(parent if parent != null else _altar).add_child(instance)
	return instance


func _add_cylinder(
	top_radius: float,
	bottom_radius: float,
	height: float,
	position: Vector3,
	material: Material,
	segments: int = 16
) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	_add_mesh(mesh, position, material)


func _add_cone(
	radius: float,
	height: float,
	position: Vector3,
	material: Material,
	segments: int = 8,
	rotation_degrees: Vector3 = Vector3.ZERO
) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	_add_mesh(mesh, position, material, rotation_degrees)


func _add_box(
	size: Vector3,
	position: Vector3,
	material: Material,
	rotation_degrees: Vector3 = Vector3.ZERO
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_mesh(mesh, position, material, rotation_degrees)


func _add_sphere(radius: float, position: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	_add_mesh(mesh, position, material)


func _add_torus(
	inner_radius: float,
	outer_radius: float,
	position: Vector3,
	rotation_degrees: Vector3,
	material: Material
) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 32
	mesh.ring_segments = 8
	_add_mesh(mesh, position, material, rotation_degrees)


func _add_spin_torus(
	inner_radius: float,
	outer_radius: float,
	position: Vector3,
	rotation_degrees: Vector3,
	material: Material
) -> void:
	var pivot := Node3D.new()
	pivot.position = position
	_altar.add_child(pivot)
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 32
	mesh.ring_segments = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.rotation_degrees = rotation_degrees
	pivot.add_child(instance)
	_spin_nodes.append(pivot)


func _update_turret_aim() -> void:
	if event_kind != "turret" or _turret_model == null:
		return
	var player: Node3D = _get_player()
	if player == null:
		return
	var direction: Vector3 = player.global_position - global_position
	direction.y = 0.0
	if direction.length() < 0.2:
		return
	# El modelo apunta a +Z local; el yaw para esa dirección es atan2(x, z).
	_turret_model.rotation.y = atan2(direction.x, direction.z)


func _trigger() -> void:
	var player: Node3D = _get_player()
	if player == null:
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var distance: float = to_player.length()

	match event_kind:
		"pulse":
			if distance <= radius:
				player.call("take_damage", pulse_damage)
				_spawn_wave()
		"slow":
			if distance <= radius:
				player.call("apply_slow", slow_multiplier, slow_duration)
				_spawn_wave()
		"turret":
			if distance <= 26.0:
				_fire_at(player)
		"mines":
			_drop_mines()
		"pull":
			if distance <= radius:
				_pull_player(player)
				_spawn_wave()
		"heal":
			_heal_enemies()
		_:
			if distance <= radius:
				player.call("take_damage", pulse_damage)
				_spawn_wave()


func _fire_at(player: Node3D) -> void:
	var target: Vector3 = player.global_position + Vector3.UP * 1.0
	var direction: Vector3 = (target - global_position).normalized()
	var muzzle_height: float = 0.75 if event_kind == "turret" else 1.9
	var origin: Vector3 = global_position + Vector3.UP * muzzle_height + direction * 0.9
	var projectile: Node3D = PROJECTILE_SCENE.instantiate() as Node3D
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.call("launch", origin, target, projectile_speed, projectile_damage, 3.5, self)
	AudioDirector.play_enemy_shot(origin)


func _pull_player(player: Node3D) -> void:
	var to_event: Vector3 = global_position - player.global_position
	to_event.y = 0.0
	if to_event.length() < 0.5:
		return
	player.call("apply_pull", to_event.normalized() * pull_force)


func _drop_mines() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	for _index in mine_count:
		var mine: Node3D = MINE_SCENE.instantiate() as Node3D
		if mine == null:
			continue
		parent.add_child(mine)
		mine.global_position = _mine_position()
		mine.call("start", mine_damage, mine_explosion_radius, _accent())


func _mine_position() -> Vector3:
	# No la suelta encima del jugador: busca un punto en el anillo del evento.
	var player: Node3D = _get_player()
	var fallback: Vector3 = global_position + Vector3(0.0, 0.15, 2.5)
	for _attempt in 6:
		var angle: float = randf() * TAU
		var distance: float = randf_range(2.5, radius)
		var position: Vector3 = global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
		position.y = 0.15
		if player == null:
			return position
		var to_player: Vector3 = player.global_position - position
		to_player.y = 0.0
		if to_player.length() >= 3.0:
			return position
	return Vector3(fallback.x, 0.15, fallback.z)


func _heal_enemies() -> void:
	var healed_any: bool = false
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node is Node3D:
			continue
		var enemy: Node3D = node as Node3D
		var offset: Vector3 = enemy.global_position - global_position
		offset.y = 0.0
		if offset.length() > radius or not enemy.has_method("heal"):
			continue
		var healed: float = float(enemy.call("heal", heal_amount))
		if healed <= 0.0:
			continue
		healed_any = true
		_spawn_heal_number(enemy.global_position + Vector3.UP * 2.0, healed)
	if healed_any:
		_spawn_wave()


func _spawn_heal_number(world_position: Vector3, amount: float) -> void:
	var number: Node3D = DAMAGE_NUMBER_SCENE.instantiate() as Node3D
	if number == null:
		return
	get_parent().add_child(number)
	number.call("show_heal", world_position, amount)


func _spawn_wave() -> void:
	var wave: Node3D = SLAM_WAVE_SCENE.instantiate() as Node3D
	if wave == null:
		return
	wave.set("color", _accent())
	get_parent().add_child(wave)
	wave.global_position = Vector3(global_position.x, 0.04, global_position.z)
	wave.call("start", radius)


func take_hit(
	_hit_zone: String,
	base_damage: float,
	_base_money: int,
	_hit_position: Vector3 = Vector3.INF
) -> void:
	if current_health <= 0.0:
		return
	current_health -= base_damage
	_update_label()
	_flash()

	if current_health <= 0.0:
		_destroy()


func _destroy() -> void:
	GameState.add_cores(core_reward)
	Toast.show_toast(
		"EVENTO COMPLETADO",
		title,
		"La arena queda un poco más tranquila.",
		"+%d ◈" % core_reward,
		_accent()
	)
	AudioDirector.play_upgrade()
	AudioDirector.play_event_destroy(global_position + Vector3.UP * 1.0)
	queue_free()


func _update_label() -> void:
	_label.text = "%s\n%d / %d" % [title, int(ceil(current_health)), int(max_health)]


func _flash() -> void:
	_label.modulate = Color(1, 1, 1, 1)
	_light.light_energy = 3.0
	var tween: Tween = create_tween()
	tween.tween_property(_label, "modulate", _accent(), 0.15)
	tween.parallel().tween_property(_light, "light_energy", 0.8, 0.15)


func _update_visuals(delta: float) -> void:
	var pulse: float = 1.0 + sin(_time * 6.0) * 0.06
	if _ring.visible:
		_ring.scale = Vector3(
			_ring_base_scale.x * pulse, _ring_base_scale.y, _ring_base_scale.z * pulse
		)
	_label.position.y = _label_base + sin(_time * 2.4) * 0.06

	for material in _glow_materials:
		material.emission_energy_multiplier = 2.2 + sin(_time * 3.0) * 0.7
	for node in _spin_nodes:
		if node != null:
			node.rotation.y += delta * 0.8


func _apply_style() -> void:
	var accent: Color = _accent()
	_core.material_override = _make_material(accent)
	_ring.material_override = _make_material(accent)
	_label.modulate = accent
	_light.light_color = accent


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	return material


func _accent() -> Color:
	var data: Dictionary = ArenaEventRegistry.get_data(event_kind)
	if data.has("color"):
		return data.get("color") as Color
	return Color(1.0, 0.16, 0.1, 1)


func get_accent() -> Color:
	# Para el minimapa y cualquier UI que necesite el color del evento.
	return _accent()


func _initial_interval() -> float:
	match event_kind:
		"slow":
			return slow_interval
		"turret":
			return maxf(projectile_interval, 2.0)
		"mines":
			return maxf(mine_interval, 2.0)
		"pull":
			return maxf(pull_interval, 2.0)
		"heal":
			return heal_interval
		_:
			return maxf(pulse_interval, 2.5)


func _interval() -> float:
	match event_kind:
		"slow":
			return slow_interval
		"turret":
			return projectile_interval
		"mines":
			return mine_interval
		"pull":
			return pull_interval
		"heal":
			return heal_interval
		_:
			return pulse_interval


func _enemy_damage_mult() -> float:
	return (
		Settings.enemy_damage_multiplier()
		* GameState.cycle_enemy_damage_mult()
		* GameState.contract_modifier("enemy_damage", 1.0)
	)


func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D
