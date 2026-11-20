class_name ContractRegistry
extends RefCounted

## Contratos de run: modificadores opcionales que aumentan la dificultad y
## pagan núcleos extra al completar la run. Se eligen antes de jugar.

const CONTRACTS: Dictionary = {
	"swift": {
		"title": "Cacería veloz",
		"description": "Los enemigos se mueven 20% más rápido.",
		"core_bonus": 2,
		"modifiers": {"enemy_speed": 1.2},
	},
	"fragile": {
		"title": "Piel fina",
		"description": "Recibís 25% más daño.",
		"core_bonus": 2,
		"modifiers": {"player_damage_taken": 1.25},
	},
	"starved": {
		"title": "Munición racionada",
		"description": "La regeneración de munición se reduce a la mitad.",
		"core_bonus": 2,
		"modifiers": {"ammo_regen": 0.5},
	},
	"rush": {
		"title": "Contrarreloj",
		"description": "Empezás con 8 segundos menos de timer.",
		"core_bonus": 3,
		"modifiers": {"timer_penalty": 8.0},
	},
	"glass": {
		"title": "Cristal",
		"description": "25% menos de vida máxima.",
		"core_bonus": 3,
		"modifiers": {"player_health": 0.75},
	},
	"endurance": {
		"title": "Piel dura",
		"description": "Los enemigos tienen 20% más de vida.",
		"core_bonus": 2,
		"modifiers": {"enemy_health": 1.2},
	},
	"berserk": {
		"title": "Furia",
		"description": "Los enemigos hacen 15% más daño.",
		"core_bonus": 2,
		"modifiers": {"enemy_damage": 1.15},
	},
}


static func get_data(contract_id: String) -> Dictionary:
	return CONTRACTS.get(contract_id, {})


static func ids() -> Array:
	return CONTRACTS.keys()


static func random_ids(count: int = 3) -> Array[String]:
	var pool: Array = CONTRACTS.keys()
	pool.shuffle()
	var picked: Array[String] = []
	for index in mini(count, pool.size()):
		picked.append(str(pool[index]))
	return picked
