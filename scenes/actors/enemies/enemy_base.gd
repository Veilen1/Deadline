extends CharacterBody3D

@export_group("Movement")
@export var move_speed: float = 3.0
@export var gravity: float = 20.0
@export var stop_distance: float = 1.5

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Money")
@export var money_head: int = 30
@export var money_torso: int = 10
@export var money_legs: int = 5

@export_group("Damage")
@export var damage_head: float = 50.0
@export var damage_torso: float = 20.0
@export var damage_legs: float = 10.0

@export_group("Zone Multipliers")
@export var damage_mult_head: float = 2.5
@export var damage_mult_torso: float = 1.0
@export var damage_mult_legs: float = 0.6
@export var money_mult_head: float = 3.0
@export var money_mult_torso: float = 1.0
@export var money_mult_legs: float = 0.5

var current_health: float


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

	# TODO: Fase 1.4 — atacar al jugador (aún no hace daño).
	# TODO: Fase 4 — comportamiento por zona (élites, composición de oleadas).


func take_hit(hit_zone: String, base_damage: float, base_money: int) -> void:
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
	EventBus.enemy_hit.emit(self, hit_zone, final_damage, final_money)
	if current_health <= 0.0:
		EventBus.enemy_killed.emit(self, hit_zone)
		queue_free()
