extends "res://scenes/actors/enemies/ranged_enemy.gd"

## Élite tirador de Zona 3: más vida, carga más rápido y alimenta la barra de
## élite del HUD como el resto de los élites.


func _ready() -> void:
	super._ready()
	add_to_group("elites")
	EventBus.boss_spawned.emit(self, max_health)


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
