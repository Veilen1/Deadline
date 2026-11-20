class_name BlessingRegistry
extends RefCounted

## Bendiciones de run: se eligen al completar una zona y duran hasta el final
## de la run. Se acumulan si se repite la misma bendición.

const BLESSINGS: Dictionary = {
	"damage": {
		"title": "Filo",
		"description": "+15% de daño con todas las armas.",
		"symbol": "✦",
	},
	"cadence": {
		"title": "Ráfaga",
		"description": "+12% de cadencia de disparo.",
		"symbol": "»",
	},
	"regen": {
		"title": "Munición viva",
		"description": "+1.5 balas/s de regeneración.",
		"symbol": "↻",
	},
	"health": {
		"title": "Vitalidad",
		"description": "+20 de vida máxima y cura 20 al elegirla.",
		"symbol": "♥",
	},
	"crit": {
		"title": "Punto débil",
		"description": "+15% de daño crítico en headshots.",
		"symbol": "◎",
	},
	"mobility": {
		"title": "Impulso",
		"description": "+10% de velocidad de movimiento.",
		"symbol": "≫",
	},
}


static func get_data(blessing_id: String) -> Dictionary:
	return BLESSINGS.get(blessing_id, {})


static func ids() -> Array:
	return BLESSINGS.keys()


static func random_ids(count: int = 3) -> Array[String]:
	var pool: Array = BLESSINGS.keys()
	pool.shuffle()
	var picked: Array[String] = []
	for index in mini(count, pool.size()):
		picked.append(str(pool[index]))
	return picked
