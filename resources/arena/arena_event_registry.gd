class_name ArenaEventRegistry
extends RefCounted

## Catálogo de eventos de arena. Cada zona elige uno al azar de su pool, así
## la misma arena cambia entre runs sin romper la identidad de la zona.
## Los colores y los tiempos son la firma visual de cada evento.

const EVENTS: Dictionary = {
	"pulse": {
		"title": "Reactor inestable",
		"description": "Pulsa daño cada 3 s en un radio de 6 m.",
		"health": 150.0,
		"reward": 2,
		"radius": 6.0,
		"color": Color(1.0, 0.16, 0.1, 1),
		"pulse_damage": 8.0,
		"pulse_interval": 3.0,
	},
	"slow": {
		"title": "Campo de hielo",
		"description": "Ralentiza al jugador dentro del radio mientras siga activo.",
		"health": 200.0,
		"reward": 2,
		"radius": 7.0,
		"color": Color(0.3, 0.8, 1.0, 1),
		"slow_multiplier": 0.6,
		"slow_duration": 0.8,
		"slow_interval": 0.6,
	},
	"turret": {
		"title": "Torreta de supresión",
		"description": "Dispara proyectiles a distancia mientras siga activa.",
		"health": 220.0,
		"reward": 3,
		"radius": 8.0,
		"color": Color(1.0, 0.78, 0.25, 1),
		"projectile_damage": 14.0,
		"projectile_interval": 1.4,
		"projectile_speed": 20.0,
	},
	"mines": {
		"title": "Fábrica de minas",
		"description": "Suelta minas que explotan al acercarte.",
		"health": 190.0,
		"reward": 3,
		"radius": 8.0,
		"color": Color(1.0, 0.45, 0.12, 1),
		"mine_interval": 3.4,
		"mine_count": 2,
		"mine_damage": 20.0,
		"mine_explosion_radius": 3.4,
	},
	"pull": {
		"title": "Ancla gravitatoria",
		"description": "Tira de vos hacia el núcleo cada pocos segundos.",
		"health": 200.0,
		"reward": 3,
		"radius": 9.0,
		"color": Color(0.68, 0.45, 1.0, 1),
		"pull_interval": 2.6,
		"pull_force": 5.5,
	},
	"heal": {
		"title": "Núcleo sanitario",
		"description": "Cura a los enemigos que estén dentro del radio.",
		"health": 170.0,
		"reward": 3,
		"radius": 8.0,
		"color": Color(0.35, 1.0, 0.55, 1),
		"heal_interval": 2.4,
		"heal_amount": 22.0,
	},
}


static func get_data(kind: String) -> Dictionary:
	return EVENTS.get(kind, {})


static func has(kind: String) -> bool:
	return EVENTS.has(kind)


static func pick(pool: PackedStringArray) -> String:
	# Devuelve "" si el pool está vacío: el evento usa su kind por defecto.
	if pool.is_empty():
		return ""
	return str(pool[randi() % pool.size()])
