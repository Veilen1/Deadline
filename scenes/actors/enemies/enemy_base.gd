extends CharacterBody3D

@export_group("Movement")
@export var move_speed: float = 3.0
@export var gravity: float = 20.0
@export var stop_distance: float = 1.5

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Attack")
@export var attack_range: float = 2.0
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 0.7

@export_group("Zone Multipliers")
@export var damage_mult_head: float = 2.5
@export var damage_mult_torso: float = 1.0
@export var damage_mult_legs: float = 0.6
@export var money_mult_head: float = 3.0
@export var money_mult_torso: float = 1.0
@export var money_mult_legs: float = 0.5

var current_health: float
var _attack_timer: float = 0.0


func _ready() -> void:
	current_health = max_health


func _physics_process(delta: float) -> void:
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

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	if to_player.length() <= attack_range and _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		if player.has_method("take_damage"):
			player.call("take_damage", attack_damage)

	# TODO: Fase 4 — comportamiento por zona (élites, composición de oleadas).


func take_hit(hit_zone: String, base_damage: float, base_money: int, hit_position: Vector3 = Vector3.INF) -> void:
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

	if current_health <= 0.0:
		EventBus.enemy_killed.emit(self, hit_zone)
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
