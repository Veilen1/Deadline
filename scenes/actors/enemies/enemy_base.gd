extends CharacterBody3D

@export_group("Movement")
@export var move_speed: float = 3.5
@export var gravity: float = 20.0
@export var stop_distance: float = 1.5

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Attack")
@export var attack_range: float = 2.2
@export var attack_damage: float = 18.0
@export var attack_cooldown: float = 0.6

@export_group("Zone Multipliers")
@export var damage_mult_head: float = 2.5
@export var damage_mult_torso: float = 1.0
@export var damage_mult_legs: float = 0.6
@export var money_mult_head: float = 3.0
@export var money_mult_torso: float = 1.0
@export var money_mult_legs: float = 0.5

var current_health: float
var _attack_timer: float = 0.0
var _climb_air: float = 0.0
var _climb_cooldown: float = 0.0
var _anim: AnimationPlayer
var _anim_lock: float = 0.0
var _dying: bool = false

@onready var model: Node3D = get_node_or_null("Model") as Node3D


func _ready() -> void:
	max_health *= (
		Settings.enemy_health_multiplier()
		* GameState.contract_modifier("enemy_health", 1.0)
		* GameState.cycle_enemy_health_mult()
	)
	attack_damage *= (
		Settings.enemy_damage_multiplier()
		* GameState.contract_modifier("enemy_damage", 1.0)
		* GameState.cycle_enemy_damage_mult()
	)
	move_speed *= (
		GameState.contract_modifier("enemy_speed", 1.0) * GameState.cycle_enemy_speed_mult()
	)
	current_health = max_health
	if model != null:
		_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_play_anim("Idle")


func _physics_process(delta: float) -> void:
	if _dying:
		return

	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0

	if to_player.length() > stop_distance:
		var direction: Vector3 = to_player.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	_face_player(player)

	_apply_vertical(delta)
	move_and_slide()
	_after_move_climb()

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	if to_player.length() <= attack_range and _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_play_anim("Attack", 0.55)
		if player.has_method("take_damage"):
			player.call("take_damage", attack_damage)

	_anim_lock = maxf(_anim_lock - delta, 0.0)
	_update_locomotion_anim()

	# TODO: Fase 4 — comportamiento por zona (élites, composición de oleadas).


func _apply_vertical(delta: float) -> void:
	_climb_cooldown = maxf(_climb_cooldown - delta, 0.0)
	if _climb_air > 0.0:
		_climb_air -= delta
		velocity.y -= gravity * delta
	elif not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


func _after_move_climb() -> void:
	# Salto corto contra obstáculos bajos para que no queden trabados.
	if is_on_wall() and is_on_floor() and _climb_cooldown <= 0.0:
		velocity.y = 7.5
		_climb_air = 0.35
		_climb_cooldown = 1.0


func heal(amount: float) -> float:
	# Devuelve cuánta vida se recuperó (0 si ya estaba al máximo o muerto).
	if current_health <= 0.0 or amount <= 0.0:
		return 0.0
	var before: float = current_health
	current_health = minf(current_health + amount, max_health)
	return current_health - before


func take_hit(hit_zone: String, base_damage: float, base_money: int, hit_position: Vector3 = Vector3.INF) -> void:
	if _dying:
		return
	# base_damage y base_money los define el arma; acá solo se aplica el multiplicador de zona.
	var damage_mult: float = 1.0
	var money_mult: float = 1.0
	match hit_zone:
		"head": damage_mult = damage_mult_head; money_mult = money_mult_head
		"torso": damage_mult = damage_mult_torso; money_mult = money_mult_torso
		"legs": damage_mult = damage_mult_legs; money_mult = money_mult_legs
		_: push_warning("EnemyBase.take_hit: zona desconocida '%s'" % hit_zone)

	var final_damage: float = base_damage * damage_mult
	var final_money: int = int(base_money * money_mult)
	current_health -= final_damage

	var effect_position: Vector3 = hit_position
	if effect_position == Vector3.INF:
		effect_position = _hitbox_position(hit_zone)
	EventBus.enemy_hit.emit(self, hit_zone, final_damage, final_money)
	EventBus.damage_number_requested.emit(effect_position, final_damage)
	if hit_zone == "head":
		EventBus.critical_hit.emit(effect_position, final_damage)

	if current_health <= 0.0:
		_die(hit_zone)
	else:
		_play_anim("Hit", 0.25)


func _play_anim(anim_name: String, lock_time: float = 0.0) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	if lock_time > 0.0:
		_anim_lock = lock_time
	if _anim.current_animation == anim_name and _anim.is_playing():
		return
	_anim.play(anim_name, 0.12)


func _update_locomotion_anim() -> void:
	if _dying or _anim_lock > 0.0:
		return
	var speed: float = Vector2(velocity.x, velocity.z).length()
	_play_anim("Walk" if speed > 0.2 else "Idle")


func _face_player(player: Node3D) -> void:
	# Orienta el cuerpo hacia el jugador sin inclinarlo; el modelo mira con -Z.
	if player == null:
		return
	var target := Vector3(player.global_position.x, global_position.y, player.global_position.z)
	if target.distance_squared_to(global_position) > 0.01:
		look_at(target, Vector3.UP)


func _die(hit_zone: String) -> void:
	if _dying:
		return
	_dying = true
	EventBus.enemy_killed.emit(self, hit_zone)
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	for child in get_children():
		if child is Area3D:
			(child as Area3D).monitorable = false
			(child as Area3D).monitoring = false
	set_physics_process(false)
	if _anim == null:
		queue_free()
		return
	_play_anim("Death", 1.2)
	await get_tree().create_timer(1.4, false).timeout
	queue_free()


func _hitbox_position(hit_zone: String) -> Vector3:
	var hitbox_name: String = ""
	match hit_zone:
		"head": hitbox_name = "HeadHitbox"
		"torso": hitbox_name = "TorsoHitbox"
		"legs": hitbox_name = "LegsHitbox"

	var hitbox: Node3D = get_node_or_null(hitbox_name) as Node3D
	if hitbox != null:
		return hitbox.global_position + Vector3.UP * 0.2
	return global_position + Vector3.UP * 2.0
