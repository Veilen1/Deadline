extends CharacterBody3D

const TRACER_SCENE: PackedScene = preload("res://scenes/effects/tracer.tscn")

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Movement")
@export var move_speed: float = 5.0
@export var gravity: float = 20.0
@export var jump_height: float = 0.9

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var camera_height: float = 1.5
@export var camera_pitch_limit_deg: float = 80.0

@export_group("Weapon")
@export var shoot_range: float = 100.0
@export var weapon_damage: float = 20.0
@export var weapon_money: int = 10

@export_group("Audio")
@export var footstep_interval: float = 0.42
@export var footstep_min_speed: float = 0.5

@onready var camera: Camera3D = $Camera3D
@onready var shoot_origin: Marker3D = $Camera3D/ShootOrigin
@onready var shoot_player: AudioStreamPlayer = $ShootPlayer
@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer

var current_health: float
var _footstep_timer: float = 0.0


func _ready() -> void:
	current_health = max_health
	mouse_sensitivity = Settings.mouse_sensitivity
	camera.fov = Settings.fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.position.y = camera_height
	# TODO: Fase 1.3 — viewmodel/brazos en primera persona (el mesh del cuerpo está oculto).


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event.is_action_pressed("shoot"):
		shoot()
		return

	if event is InputEventMouseMotion:
		# Yaw sobre el cuerpo; pitch sobre la cámara (primera persona).
		rotate_y(-event.relative.x * mouse_sensitivity)
		var pitch_limit: float = deg_to_rad(camera_pitch_limit_deg)
		var invert: float = -1.0 if Settings.invert_y else 1.0
		camera.rotation.x = clampf(
			camera.rotation.x - event.relative.y * mouse_sensitivity * invert,
			-pitch_limit,
			pitch_limit
		)


func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)

	var body_basis: Basis = global_basis
	var direction: Vector3 = body_basis.x * input_vector.x + body_basis.z * input_vector.y
	direction.y = 0.0
	if direction.length_squared() > 0.0:
		direction = direction.normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		if Input.is_action_just_pressed("jump"):
			# Salto de medio cuerpo: v = sqrt(2 * g * h).
			velocity.y = sqrt(2.0 * gravity * jump_height)

	move_and_slide()

	_update_footsteps(delta)


func _update_footsteps(delta: float) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or horizontal_speed < footstep_min_speed:
		_footstep_timer = 0.0
		return

	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return

	_footstep_timer = footstep_interval
	footstep_player.pitch_scale = randf_range(0.9, 1.1)
	footstep_player.play()


func take_damage(amount: float) -> void:
	# Ignora daño si ya está muerto.
	if current_health <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	EventBus.player_damaged.emit(amount)

	if current_health <= 0.0:
		EventBus.player_died.emit()


func apply_meta_upgrades(upgrades: Dictionary) -> void:
	# Aplica los bonus comprados en el hub. Se llama una vez al empezar la run.
	weapon_damage += float(upgrades.get("damage_bonus", 0.0))
	max_health += float(upgrades.get("health_bonus", 0.0))
	current_health = max_health


func shoot() -> void:
	# Raycast desde el centro de la cámara hacia donde se mira.
	var screen_center: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var origin: Vector3 = camera.project_ray_origin(screen_center)
	var direction: Vector3 = camera.project_ray_normal(screen_center)

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * shoot_range
	)
	query.collide_with_areas = true
	query.exclude = _build_ray_exclude_list()

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var result: Dictionary = space_state.intersect_ray(query)

	# El tracer llega hasta el impacto o hasta el alcance máximo si falla.
	var end_point: Vector3 = origin + direction * shoot_range
	if not result.is_empty():
		end_point = result.get("position", end_point)

		var collider: Node = result.get("collider") as Node
		if collider != null:
			var hit_zone: String = _hit_zone_from_collider(collider)
			if not hit_zone.is_empty():
				var enemy: Node = collider.get_parent()
				if enemy != null and enemy.has_method("take_hit"):
					var hit_position: Vector3 = result.get("position", Vector3.INF)
					enemy.call("take_hit", hit_zone, weapon_damage, weapon_money, hit_position)

	_spawn_tracer(end_point)
	shoot_player.pitch_scale = randf_range(0.95, 1.05)
	shoot_player.play()
	# TODO: Fase 1.4 — cooldown y retroceso del arma.


func _spawn_tracer(to: Vector3) -> void:
	var tracer: Node3D = TRACER_SCENE.instantiate()
	get_parent().add_child(tracer)
	tracer.call("fire", shoot_origin.global_position, to)


func _build_ray_exclude_list() -> Array[RID]:
	# Excluye los cuerpos de los enemigos: el rayo debe golpear sus Area3D (hitboxes).
	var excluded: Array[RID] = [get_rid()]
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if enemy is CollisionObject3D:
			excluded.append(enemy.get_rid())
	return excluded


func _hit_zone_from_collider(collider: Node) -> String:
	var hitbox_name: String = String(collider.name)
	match hitbox_name:
		"HeadHitbox":
			return "head"
		"TorsoHitbox":
			return "torso"
		"LegsHitbox":
			return "legs"
		_:
			return ""
