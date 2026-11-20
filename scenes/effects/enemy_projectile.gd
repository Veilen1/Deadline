extends CharacterBody3D

## Proyectil del tirador. Viaja en línea recta, daña al jugador al impactar
## y se destruye contra paredes, enemigos u obstáculos.

@export var lifetime: float = 3.5

var _damage: float = 10.0
var _age: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING


func launch(
	origin: Vector3,
	target: Vector3,
	speed: float,
	damage: float,
	life: float = 3.5,
	shooter: Node = null
) -> void:
	global_position = origin
	_damage = damage
	lifetime = life
	_age = 0.0

	var direction: Vector3 = target - origin
	if direction.length_squared() < 0.001:
		direction = Vector3.FORWARD
	direction = direction.normalized()
	velocity = direction * speed

	# El tirador no debe chocar con su propio proyectil al disparar.
	if shooter is CollisionObject3D:
		add_collision_exception_with(shooter as CollisionObject3D)

	var up: Vector3 = Vector3.UP
	if absf(direction.dot(up)) > 0.99:
		up = Vector3.FORWARD
	look_at(global_position + direction, up)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	var collision: KinematicCollision3D = move_and_collide(velocity * delta)
	if collision == null:
		return

	var collider: Object = collision.get_collider()
	if collider is Node and (collider as Node).is_in_group("player"):
		if collider.has_method("take_damage"):
			collider.call("take_damage", _damage)
	queue_free()
