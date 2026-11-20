extends CharacterBody3D

const TRACER_SCENE: PackedScene = preload("res://scenes/effects/tracer.tscn")

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Movement")
@export var move_speed: float = 5.0
@export var gravity: float = 20.0
@export var jump_height: float = 0.9
@export var dash_speed: float = 16.0
@export var dash_duration: float = 0.13
@export var dash_cooldown: float = 0.9
@export var slide_speed_multiplier: float = 1.7
@export var slide_duration: float = 0.42
@export var slide_cooldown: float = 1.0
@export var slide_camera_height: float = 0.9

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var camera_height: float = 1.5
@export var camera_pitch_limit_deg: float = 80.0

@export_group("Weapon")
@export var weapon_data: WeaponData

@export_group("Audio")
@export var footstep_interval: float = 0.42
@export var footstep_min_speed: float = 0.5

@export_group("Style Camera")
@export var style_fov_per_rank: float = 1.6
@export var shake_duration: float = 0.18
@export var shake_strength: float = 0.03

@onready var camera: Camera3D = $Camera3D
@onready var shoot_origin: Marker3D = $Camera3D/ShootOrigin
@onready var weapon_view: Node3D = $Camera3D/WeaponView
@onready var dash_trail: CPUParticles3D = $Camera3D/DashTrail
@onready var shoot_player: AudioStreamPlayer = $ShootPlayer
@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var dash_player: AudioStreamPlayer = $DashPlayer
@onready var rank_up_player: AudioStreamPlayer = $RankUpPlayer
@onready var weapon_switch_player: AudioStreamPlayer = $WeaponSwitchPlayer

var current_health: float
var damage_bonus: float = 0.0
var crit_bonus: float = 0.0
var crit_refund: float = 0.0
var damage_reduction: float = 0.0
var max_ammo: int = 0
var ammo_capacity_bonus: int = 0
var current_ammo: int = 0
var ammo_regen_bonus: float = 0.0
var fire_rate_bonus: float = 0.0

var _weapon_ids: Array[String] = []
var _current_weapon_id: String = ""
var _ammo_by_weapon: Dictionary = {}
var _footstep_timer: float = 0.0
var _fire_timer: float = 0.0
var _regen_delay_timer: float = 0.0
var _ammo_regen_accumulator: float = 0.0
var _base_fov: float = 75.0
var _target_fov: float = 75.0
var _style_rank: int = 0
var _shake_time: float = 0.0
var _shake_peak: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _dash_fov_kick: float = 0.0
var _slide_timer: float = 0.0
var _slide_cooldown_timer: float = 0.0
var _slide_direction: Vector3 = Vector3.ZERO
var _contract_damage_taken: float = 1.0
var _contract_ammo_regen: float = 1.0


func _ready() -> void:
	current_health = max_health
	_contract_damage_taken = GameState.contract_modifier("player_damage_taken", 1.0)
	_contract_ammo_regen = GameState.contract_modifier("ammo_regen", 1.0)
	var equipped_weapon: WeaponData = WeaponRegistry.get_data(GameState.equipped_weapon)
	if equipped_weapon != null:
		weapon_data = equipped_weapon
	if weapon_data == null:
		push_warning("Player: falta weapon_data")

	_weapon_ids = GameState.owned_weapons.duplicate()
	_current_weapon_id = GameState.equipped_weapon
	if not _weapon_ids.has(_current_weapon_id):
		_weapon_ids.append(_current_weapon_id)

	_init_ammo()
	if weapon_view != null and weapon_view.has_method("setup"):
		weapon_view.call("setup", _current_weapon_id)
	if dash_trail != null:
		dash_trail.emitting = false

	Settings.settings_changed.connect(_apply_live_settings)
	StyleSystem.style_changed.connect(_on_style_changed)
	StyleSystem.rank_up.connect(_on_rank_up)
	_apply_live_settings()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.position.y = camera_height
	# TODO: Fase 1.3 — viewmodel/brazos en primera persona (el mesh del cuerpo está oculto).


func _init_ammo() -> void:
	# Munición independiente por arma: cada una conserva su cargador.
	_ammo_by_weapon.clear()
	for id: String in _weapon_ids:
		var data: WeaponData = WeaponRegistry.get_data(id)
		if data == null:
			continue
		_ammo_by_weapon[id] = data.magazine_size + ammo_capacity_bonus

	if weapon_data != null:
		max_ammo = weapon_data.magazine_size + ammo_capacity_bonus
	else:
		max_ammo = 0
	current_ammo = clampi(int(_ammo_by_weapon.get(_current_weapon_id, max_ammo)), 0, max_ammo)


func _set_current_ammo(value: int) -> void:
	current_ammo = clampi(value, 0, max_ammo)
	if not _current_weapon_id.is_empty():
		_ammo_by_weapon[_current_weapon_id] = current_ammo
	EventBus.ammo_changed.emit(current_ammo, max_ammo)


func get_dash_cooldown_ratio() -> float:
	if dash_cooldown <= 0.0:
		return 1.0
	return 1.0 - clampf(_dash_cooldown_timer / dash_cooldown, 0.0, 1.0)


func _process(delta: float) -> void:
	if not is_instance_valid(camera):
		return

	camera.fov = lerpf(camera.fov, _target_fov + _dash_fov_kick, 1.0 - exp(-10.0 * delta))
	_dash_fov_kick = lerpf(_dash_fov_kick, 0.0, 1.0 - exp(-9.0 * delta))

	var target_height: float = slide_camera_height if _slide_timer > 0.0 else camera_height
	camera.position.y = lerpf(camera.position.y, target_height, 1.0 - exp(-12.0 * delta))

	if _shake_time > 0.0:
		_shake_time = maxf(_shake_time - delta, 0.0)
		var ratio: float = _shake_time / maxf(shake_duration, 0.01)
		camera.h_offset = randf_range(-1.0, 1.0) * _shake_peak * ratio
		camera.v_offset = randf_range(-1.0, 1.0) * _shake_peak * ratio
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func _on_style_changed(_rank: String, rank_index: int, _progress: float, _combo: int) -> void:
	_style_rank = rank_index
	_target_fov = _base_fov + float(_style_rank) * style_fov_per_rank


func _on_rank_up(_rank: String, rank_index: int) -> void:
	_shake_time = shake_duration
	_shake_peak = shake_strength * (1.0 + float(rank_index) * 0.25)
	rank_up_player.play()


func _input_direction() -> Vector3:
	var input_vector: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var body_basis: Basis = global_basis
	var direction: Vector3 = body_basis.x * input_vector.x + body_basis.z * input_vector.y
	direction.y = 0.0
	if direction.length_squared() <= 0.0:
		return Vector3.ZERO
	return direction.normalized()


func _try_dash() -> void:
	if _dash_cooldown_timer > 0.0 or _dash_timer > 0.0:
		return

	var direction: Vector3 = _input_direction()
	if direction == Vector3.ZERO:
		direction = -global_basis.z
		direction.y = 0.0
		direction = direction.normalized()

	_dash_direction = direction
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_slide_timer = 0.0
	_shake_time = 0.12
	_shake_peak = 0.02
	_dash_fov_kick = 7.0
	if dash_trail != null:
		dash_trail.restart()
		dash_trail.emitting = true
	dash_player.pitch_scale = randf_range(0.95, 1.05)
	dash_player.play()


func _try_slide() -> void:
	if _slide_cooldown_timer > 0.0 or _slide_timer > 0.0 or not is_on_floor():
		return

	var direction: Vector3 = _input_direction()
	if direction == Vector3.ZERO:
		direction = Vector3(velocity.x, 0.0, velocity.z)
		if direction.length_squared() <= 0.01:
			direction = -global_basis.z
			direction.y = 0.0
		direction = direction.normalized()

	_slide_direction = direction
	_slide_timer = slide_duration
	_slide_cooldown_timer = slide_cooldown
	_dash_timer = 0.0
	_shake_time = 0.08
	_shake_peak = 0.012
	dash_player.pitch_scale = 0.78
	dash_player.play()


func _switch_weapon(index: int) -> void:
	if index < 0 or index >= _weapon_ids.size():
		return

	var weapon_id: String = _weapon_ids[index]
	if weapon_id == _current_weapon_id:
		return

	var data: WeaponData = WeaponRegistry.get_data(weapon_id)
	if data == null:
		return

	# Guarda el cargador del arma que se deja y recupera el de la nueva.
	_ammo_by_weapon[_current_weapon_id] = current_ammo
	_current_weapon_id = weapon_id
	weapon_data = data
	max_ammo = data.magazine_size + ammo_capacity_bonus
	current_ammo = clampi(int(_ammo_by_weapon.get(weapon_id, max_ammo)), 0, max_ammo)
	_fire_timer = 0.0
	_regen_delay_timer = 0.0
	_ammo_regen_accumulator = 0.0
	EventBus.ammo_changed.emit(current_ammo, max_ammo)
	EventBus.weapon_changed.emit(data.weapon_name)
	if weapon_view != null and weapon_view.has_method("switch_to"):
		weapon_view.call("switch_to", weapon_id)
	weapon_switch_player.play()


func _apply_live_settings() -> void:
	if is_instance_valid(camera):
		_base_fov = Settings.fov
		_target_fov = _base_fov + float(_style_rank) * style_fov_per_rank
		camera.fov = _target_fov
	mouse_sensitivity = Settings.mouse_sensitivity


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SHIFT:
				_try_dash()
			KEY_CTRL:
				_try_slide()
			KEY_1:
				_switch_weapon(0)
			KEY_2:
				_switch_weapon(1)
			KEY_3:
				_switch_weapon(2)
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
	_fire_timer = maxf(_fire_timer - delta, 0.0)
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_slide_cooldown_timer = maxf(_slide_cooldown_timer - delta, 0.0)
	if dash_trail != null:
		dash_trail.emitting = _dash_timer > 0.0
	_update_ammo_regen(delta)

	var input_vector: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)

	var body_basis: Basis = global_basis
	var direction: Vector3 = body_basis.x * input_vector.x + body_basis.z * input_vector.y
	direction.y = 0.0
	if direction.length_squared() > 0.0:
		direction = direction.normalized()

	if _dash_timer > 0.0:
		velocity.x = _dash_direction.x * dash_speed
		velocity.z = _dash_direction.z * dash_speed
		_dash_timer = maxf(_dash_timer - delta, 0.0)
	elif _slide_timer > 0.0:
		velocity.x = _slide_direction.x * move_speed * slide_speed_multiplier
		velocity.z = _slide_direction.z * move_speed * slide_speed_multiplier
		_slide_timer = maxf(_slide_timer - delta, 0.0)
	else:
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

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("shoot"):
		shoot()


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

	var final_damage: float = amount * (1.0 - clampf(damage_reduction, 0.0, 0.8))
	final_damage *= _contract_damage_taken
	current_health = maxf(current_health - final_damage, 0.0)
	EventBus.player_damaged.emit(final_damage)

	if current_health <= 0.0:
		EventBus.player_died.emit()


func apply_meta_upgrades(upgrades: Dictionary) -> void:
	# Aplica los bonus comprados en el hub. Se llama una vez al empezar la run.
	damage_bonus += float(upgrades.get("damage_bonus", 0.0))
	crit_bonus += float(upgrades.get("crit_bonus", 0.0))
	crit_refund += float(upgrades.get("crit_refund", 0.0))
	damage_reduction += float(upgrades.get("damage_reduction", 0.0))
	max_health += float(upgrades.get("health_bonus", 0.0))
	max_health *= GameState.contract_modifier("player_health", 1.0)
	ammo_capacity_bonus += int(upgrades.get("ammo_capacity_bonus", 0))
	if weapon_data != null:
		max_ammo = weapon_data.magazine_size + ammo_capacity_bonus
	ammo_regen_bonus += float(upgrades.get("ammo_regen_bonus", 0.0))
	fire_rate_bonus += float(upgrades.get("fire_rate_bonus", 0.0))
	current_health = max_health
	_init_ammo()
	_set_current_ammo(max_ammo)


func _update_ammo_regen(delta: float) -> void:
	if weapon_data == null or current_ammo >= max_ammo:
		_ammo_regen_accumulator = 0.0
		return

	if _regen_delay_timer > 0.0:
		_regen_delay_timer -= delta
		return

	var rate: float = maxf(
		(weapon_data.ammo_regen_per_second + ammo_regen_bonus) * _contract_ammo_regen, 0.0
	)
	if rate <= 0.0:
		return

	_ammo_regen_accumulator += rate * delta
	var rounds: int = int(_ammo_regen_accumulator)
	if rounds <= 0:
		return

	_ammo_regen_accumulator -= float(rounds)
	_set_current_ammo(current_ammo + rounds)


func shoot() -> void:
	if weapon_data == null or _fire_timer > 0.0 or current_ammo <= 0:
		return

	current_ammo -= 1
	_fire_timer = 1.0 / maxf(weapon_data.shots_per_second * (1.0 + fire_rate_bonus), 0.01)
	_regen_delay_timer = weapon_data.regen_delay
	_ammo_regen_accumulator = 0.0
	_set_current_ammo(current_ammo)

	# Raycast desde el centro de la cámara hacia donde se mira.
	var screen_center: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var origin: Vector3 = camera.project_ray_origin(screen_center)
	var direction: Vector3 = camera.project_ray_normal(screen_center)

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * weapon_data.range
	)
	query.collide_with_areas = true
	query.exclude = _build_ray_exclude_list()

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var result: Dictionary = space_state.intersect_ray(query)

	# El tracer llega hasta el impacto o hasta el alcance máximo si falla.
	var end_point: Vector3 = origin + direction * weapon_data.range
	if not result.is_empty():
		end_point = result.get("position", end_point)

		var collider: Node = result.get("collider") as Node
		if collider != null:
			var hit_zone: String = _hit_zone_from_collider(collider)
			if not hit_zone.is_empty():
				var enemy: Node = collider.get_parent()
				if enemy != null and enemy.has_method("take_hit"):
					var hit_position: Vector3 = result.get("position", Vector3.INF)
					var damage: float = weapon_data.damage + damage_bonus
					if hit_zone == "head":
						damage *= 1.0 + crit_bonus
						# Ejecutor: probabilidad de recuperar la bala del headshot.
						if crit_refund > 0.0 and current_ammo < max_ammo:
							if randf() < clampf(crit_refund, 0.0, 1.0):
								_set_current_ammo(current_ammo + 1)
					enemy.call("take_hit", hit_zone, damage, weapon_data.money_per_hit, hit_position)

	_spawn_tracer(end_point)
	if weapon_view != null and weapon_view.has_method("flash"):
		weapon_view.call("flash")
	shoot_player.pitch_scale = randf_range(0.95, 1.05)
	shoot_player.play()


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
