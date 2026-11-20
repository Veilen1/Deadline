extends "res://scenes/actors/enemies/enemy_base.gd"

## Tirador de Zona 3: mantiene la distancia, se desplaza de costado y dispara
## proyectiles telegrafiados. Durante la carga se queda quieto y expone su
## ojo brillante, que es la ventana para atacarlo.

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/effects/enemy_projectile.tscn")

enum State { REPOSITION, CHARGE, RECOVER }

@export_group("Ranged")
@export var preferred_min_distance: float = 6.0
@export var preferred_max_distance: float = 11.0
@export var strafe_speed_multiplier: float = 0.75
@export var shot_interval: float = 1.9
@export var charge_time: float = 0.5
@export var recover_time: float = 0.25
@export var projectile_speed: float = 22.0
@export var projectile_damage: float = 14.0
@export var projectile_lifetime: float = 3.5
@export var aim_height: float = 0.9

var _state: State = State.REPOSITION
var _state_timer: float = 0.0
var _shot_timer: float = 1.0
var _strafe_timer: float = 1.5
var _strafe_sign: float = 1.0
var _charge_eye: MeshInstance3D


func _ready() -> void:
	super._ready()
	projectile_damage *= (
		Settings.enemy_damage_multiplier() * GameState.contract_modifier("enemy_damage", 1.0)
	)
	_charge_eye = get_node_or_null("ChargeEye") as MeshInstance3D
	if _charge_eye != null:
		_charge_eye.hide()
	_shot_timer = randf_range(0.8, 1.6)
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0


func _physics_process(delta: float) -> void:
	var player: Node3D = _get_player()
	if player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity(delta)
		move_and_slide()
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var distance: float = to_player.length()
	var direction: Vector3 = to_player.normalized() if distance > 0.01 else Vector3.ZERO

	_shot_timer = maxf(_shot_timer - delta, 0.0)
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_timer = randf_range(1.1, 2.2)
		_strafe_sign *= -1.0

	match _state:
		State.REPOSITION:
			_process_reposition(direction, distance, player)
		State.CHARGE:
			_process_charge(delta, player)
		State.RECOVER:
			velocity.x = 0.0
			velocity.z = 0.0
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = State.REPOSITION

	_apply_gravity(delta)
	move_and_slide()


func _process_reposition(direction: Vector3, distance: float, player: Node3D) -> void:
	var desired: Vector3 = Vector3.ZERO
	if distance > preferred_max_distance:
		desired = direction * move_speed
	elif distance < preferred_min_distance:
		desired = -direction * move_speed
	else:
		desired = direction.cross(Vector3.UP) * move_speed * strafe_speed_multiplier * _strafe_sign

	velocity.x = desired.x
	velocity.z = desired.z

	if _shot_timer <= 0.0 and distance <= preferred_max_distance + 4.0 and _has_line_of_sight(player):
		_begin_charge()


func _begin_charge() -> void:
	_state = State.CHARGE
	_state_timer = charge_time
	velocity.x = 0.0
	velocity.z = 0.0
	if _charge_eye != null:
		_charge_eye.show()
		_charge_eye.scale = Vector3.ONE * 0.6


func _process_charge(delta: float, player: Node3D) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer -= delta
	if _charge_eye != null:
		var charge: float = 1.0 - clampf(_state_timer / maxf(charge_time, 0.01), 0.0, 1.0)
		_charge_eye.scale = Vector3.ONE * lerpf(0.6, 1.6, charge)

	if _state_timer <= 0.0:
		_fire(player)
		_state = State.RECOVER
		_state_timer = recover_time
		_shot_timer = shot_interval


func _fire(player: Node3D) -> void:
	if _charge_eye != null:
		_charge_eye.hide()
	if player == null:
		return

	var direction: Vector3 = player.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	direction = direction.normalized()

	var origin: Vector3 = global_position + Vector3.UP * aim_height + direction * 0.7
	var target: Vector3 = player.global_position + Vector3.UP * 1.0
	var projectile: Node3D = PROJECTILE_SCENE.instantiate() as Node3D
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.call(
		"launch", origin, target, projectile_speed, projectile_damage, projectile_lifetime, self
	)


func _has_line_of_sight(player: Node3D) -> bool:
	var origin: Vector3 = global_position + Vector3.UP * aim_height
	var target: Vector3 = player.global_position + Vector3.UP * 1.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, target)
	var exclude: Array[RID] = [get_rid()]
	query.exclude = exclude
	query.collide_with_areas = false

	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	var collider: Object = result.get("collider")
	return collider is Node and (collider as Node).is_in_group("player")


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D
