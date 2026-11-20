class_name SkillTree
extends RefCounted

## Datos del árbol de habilidades. Los nodos se desbloquean si al menos uno
## de sus requisitos ya está desbloqueado (adyacencia).

const ROOT_ID: String = "root"

const NODES: Dictionary = {
	"root": {
		"title": "Base",
		"description": "Núcleo del árbol. Desde acá crecen las tres ramas.",
		"cost": 0,
		"requires": [],
		"position": Vector2(0.5, 0.9),
		"effects": {},
	},
	"dmg_1": {
		"title": "Calibre",
		"description": "Ajuste del arma para golpear más fuerte.",
		"cost": 60,
		"requires": ["root"],
		"position": Vector2(0.2, 0.68),
		"effects": {"damage_bonus": 5.0},
	},
	"hp_1": {
		"title": "Resistencia",
		"description": "Entrenamiento físico para aguantar más daño.",
		"cost": 70,
		"requires": ["root"],
		"position": Vector2(0.5, 0.68),
		"effects": {"health_bonus": 20.0},
	},
	"time_1": {
		"title": "Reloj de arena",
		"description": "Más tiempo base para cada run.",
		"cost": 50,
		"requires": ["root"],
		"position": Vector2(0.8, 0.68),
		"effects": {"time_bonus": 10.0},
	},
	"dmg_2": {
		"title": "Munición pesada",
		"description": "Segunda capa de daño para el arma.",
		"cost": 120,
		"requires": ["dmg_1"],
		"position": Vector2(0.14, 0.44),
		"effects": {"damage_bonus": 5.0},
	},
	"fire_rate_1": {
		"title": "Gatillo rápido",
		"description": "Reduce el intervalo entre disparos.",
		"cost": 110,
		"requires": ["dmg_1"],
		"position": Vector2(0.34, 0.44),
		"effects": {"fire_rate_bonus": 0.15},
	},
	"hp_2": {
		"title": "Segundo aire",
		"description": "Más vida máxima para la siguiente run.",
		"cost": 140,
		"requires": ["hp_1"],
		"position": Vector2(0.5, 0.44),
		"effects": {"health_bonus": 20.0},
	},
	"ammo_cap_1": {
		"title": "Cargador extendido",
		"description": "Más balas por cargador.",
		"cost": 80,
		"requires": ["time_1"],
		"position": Vector2(0.74, 0.44),
		"effects": {"ammo_capacity_bonus": 4.0},
	},
	"ammo_regen_1": {
		"title": "Recarga viva",
		"description": "Las balas vuelven más rápido.",
		"cost": 120,
		"requires": ["ammo_cap_1"],
		"position": Vector2(0.74, 0.2),
		"effects": {"ammo_regen_bonus": 1.5},
	},
}


static func get_node_data(skill_id: String) -> Dictionary:
	return NODES.get(skill_id, {})
