class_name SkillTree
extends RefCounted

## Árbol de habilidades con nodo central de daño y cuatro ramas cardinales.
## Cada nodo tiene nivel máximo 5, 3 o 1. Los nodos se habilitan por adyacencia.

const ROOT_ID: String = "damage_core"

const NODES: Dictionary = {
	"damage_core": {
		"title": "Núcleo de daño",
		"symbol": "✦",
		"description": "Aumenta el daño básico del arma. Es el centro del árbol.",
		"max_level": 5,
		"base_cost": 2,
		"requires": [],
		"position": Vector2(0.5, 0.5),
		"effects": {"damage_bonus": 2.0},
	},
	"precision": {
		"title": "Precisión",
		"symbol": "◎",
		"description": "Los headshots hacen más daño y alimentan mejor el estilo.",
		"max_level": 3,
		"base_cost": 3,
		"requires": ["damage_core"],
		"position": Vector2(0.5, 0.32),
		"effects": {"crit_bonus": 0.15},
	},
	"executioner": {
		"title": "Ejecutor",
		"symbol": "★",
		"description": "Cada headshot tiene 25% de probabilidad de no gastar munición.",
		"max_level": 1,
		"base_cost": 6,
		"requires": ["precision"],
		"position": Vector2(0.5, 0.14),
		"effects": {"crit_refund": 0.25},
	},
	"cadence": {
		"title": "Cadencia",
		"symbol": "»",
		"description": "Reduce el intervalo entre disparos.",
		"max_level": 5,
		"base_cost": 3,
		"requires": ["damage_core"],
		"position": Vector2(0.68, 0.5),
		"effects": {"fire_rate_bonus": 0.08},
	},
	"extended_mag": {
		"title": "Cargador",
		"symbol": "≡",
		"description": "Más balas por cargador.",
		"max_level": 3,
		"base_cost": 4,
		"requires": ["cadence"],
		"position": Vector2(0.86, 0.5),
		"effects": {"ammo_capacity_bonus": 4.0},
	},
	"vitality": {
		"title": "Vitalidad",
		"symbol": "♥",
		"description": "Más vida máxima para la próxima run.",
		"max_level": 5,
		"base_cost": 3,
		"requires": ["damage_core"],
		"position": Vector2(0.5, 0.68),
		"effects": {"health_bonus": 15.0},
	},
	"armor": {
		"title": "Armadura",
		"symbol": "◆",
		"description": "Reduce el daño recibido en un 15%.",
		"max_level": 1,
		"base_cost": 8,
		"requires": ["vitality"],
		"position": Vector2(0.5, 0.86),
		"effects": {"damage_reduction": 0.15},
	},
	"time": {
		"title": "Reloj de arena",
		"symbol": "◷",
		"description": "Más tiempo base para cada run (+8 s por nivel).",
		"max_level": 3,
		"base_cost": 2,
		"requires": ["damage_core"],
		"position": Vector2(0.32, 0.5),
		"effects": {"time_bonus": 8.0},
	},
	"regen": {
		"title": "Recarga viva",
		"symbol": "↻",
		"description": "Las balas vuelven más rápido.",
		"max_level": 5,
		"base_cost": 4,
		"requires": ["time"],
		"position": Vector2(0.14, 0.5),
		"effects": {"ammo_regen_bonus": 1.0},
	},
}


static func get_node_data(skill_id: String) -> Dictionary:
	return NODES.get(skill_id, {})
