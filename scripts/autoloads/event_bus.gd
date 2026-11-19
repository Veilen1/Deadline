extends Node
## Hub de señales puras. Sin estado y sin lógica.
## Los sistemas se comunican exclusivamente a través de estas señales.

# hit_zone: "head" | "torso" | "legs"
signal enemy_hit(enemy: Node, hit_zone: String, damage: float, money_value: int)
signal enemy_killed(enemy: Node, hit_zone: String)
signal damage_number_requested(world_position: Vector3, amount: float)

signal player_damaged(amount: float)
signal player_died

signal boss_spawned(boss: Node, max_health: float)
signal boss_health_changed(current_health: float, max_health: float)
signal boss_defeated

signal powerup_collected(powerup_type: String, value: float)

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

signal zone_completed(zone_id: String)
