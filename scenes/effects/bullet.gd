extends Node3D

## Bala visual del jugador. El daño sigue siendo hitscan: esto solo recorre
## el trayecto desde la boca del arma hasta el punto de impacto y se libera.
## Optimizada: sin colisiones, sin luces y con mallas de pocos polígonos.

@export var speed: float = 90.0
@export var max_lifetime: float = 1.5

var _direction: Vector3 = Vector3.FORWARD
var _remaining: float = 0.0
var _age: float = 0.0


func _ready() -> void:
	add_to_group("player_bullets")


func fire(from: Vector3, to: Vector3) -> void:
	global_position = from
	var delta: Vector3 = to - from
	_remaining = delta.length()
	if _remaining <= 0.01:
		queue_free()
		return

	_direction = delta / _remaining
	var up: Vector3 = Vector3.UP
	if absf(_direction.dot(Vector3.UP)) > 0.99:
		up = Vector3.FORWARD
	look_at(to, up)


func _process(delta: float) -> void:
	_age += delta
	if _age >= max_lifetime:
		queue_free()
		return

	var step: float = speed * delta
	if step >= _remaining:
		queue_free()
		return

	global_position += _direction * step
	_remaining -= step
