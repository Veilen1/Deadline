extends "res://scenes/actors/enemies/ranged_enemy.gd"

## Élite tirador: dispara una ráfaga de tres proyectiles en abanico. Cada
## proyectil mantiene el telegraph de la carga y la velocidad del tirador base.

const SPREAD_PROJECTILE_SCENE: PackedScene = preload("res://scenes/effects/enemy_projectile.tscn")

@export_group("Elite Burst")
@export var burst_count: int = 3
@export var burst_spread_degrees: float = 9.0


func _ready() -> void:
	super._ready()
	add_to_group("elites")
	EventBus.boss_spawned.emit(self, max_health)


func _fire(player: Node3D) -> void:
	if _charge_eye != null:
		_charge_eye.hide()
	_play_anim("Shoot", 0.4)
	if player == null:
		return

	var direction: Vector3 = player.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	direction = direction.normalized()

	var origin: Vector3 = global_position + Vector3.UP * aim_height + direction * 0.7
	var aim: Vector3 = player.global_position + Vector3.UP * 1.0
	var shots: int = maxi(burst_count, 1)
	var mid: float = float(shots - 1) * 0.5
	var spread: float = deg_to_rad(burst_spread_degrees)

	for index in shots:
		var angle: float = (float(index) - mid) * spread
		var offset: Vector3 = (aim - origin).rotated(Vector3.UP, angle)
		var projectile: Node3D = SPREAD_PROJECTILE_SCENE.instantiate() as Node3D
		if projectile == null:
			continue
		get_parent().add_child(projectile)
		projectile.call(
			"launch",
			origin,
			origin + offset,
			projectile_speed,
			projectile_damage,
			projectile_lifetime,
			self
		)

	AudioDirector.play_enemy_shot(global_position + Vector3.UP * 1.0)


func take_hit(
	hit_zone: String,
	base_damage: float,
	base_money: int,
	hit_position: Vector3 = Vector3.INF
) -> void:
	super.take_hit(hit_zone, base_damage, base_money, hit_position)
	if current_health > 0.0:
		EventBus.boss_health_changed.emit(current_health, max_health)
	else:
		EventBus.boss_defeated.emit()
