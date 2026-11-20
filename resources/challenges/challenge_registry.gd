class_name ChallengeRegistry
extends RefCounted

## Desafíos persistentes. Algunos desbloquean armas; otros entregan núcleos
## que se reclaman desde la pantalla de Desafíos.

const CHALLENGES: Dictionary = {
	"smg_unlock": {
		"title": "Puntería de élite",
		"description": "Acertá 40 headshots para desbloquear la Avispa.",
		"stat": "headshots",
		"target": 40,
		"reward_type": "weapon",
		"reward_id": "smg",
	},
	"shotgun_unlock": {
		"title": "Sobreviviente",
		"description": "Completá una run para desbloquear el Trueno.",
		"stat": "runs_completed",
		"target": 1,
		"reward_type": "weapon",
		"reward_id": "shotgun",
	},
	"elite_hunter": {
		"title": "Cazador de élites",
		"description": "Eliminá 10 élites para ganar 3 núcleos.",
		"stat": "elites_killed",
		"target": 10,
		"reward_type": "cores",
		"reward_id": "3",
	},
	"hound_slayer": {
		"title": "Domador de sabuesos",
		"description": "Eliminá 25 sabuesos para ganar 2 núcleos.",
		"stat": "hounds_killed",
		"target": 25,
		"reward_type": "cores",
		"reward_id": "2",
	},
	"zone_veteran": {
		"title": "Veterano de zonas",
		"description": "Completá 6 zonas para ganar 3 núcleos.",
		"stat": "zones_cleared",
		"target": 6,
		"reward_type": "cores",
		"reward_id": "3",
	},
	"headhunter": {
		"title": "Cazacabezas",
		"description": "Acertá 150 headshots para ganar 3 núcleos.",
		"stat": "headshots",
		"target": 150,
		"reward_type": "cores",
		"reward_id": "3",
	},
	"survivor": {
		"title": "Racha de superviviente",
		"description": "Completá 5 runs para ganar 5 núcleos.",
		"stat": "runs_completed",
		"target": 5,
		"reward_type": "cores",
		"reward_id": "5",
	},
}


static func get_data(challenge_id: String) -> Dictionary:
	return CHALLENGES.get(challenge_id, {})


static func ids() -> Array:
	return CHALLENGES.keys()


static func weapon_unlock_for(weapon_id: String) -> String:
	for id in CHALLENGES:
		var data: Dictionary = CHALLENGES[id]
		if (
			str(data.get("reward_type", "")) == "weapon"
			and str(data.get("reward_id", "")) == weapon_id
		):
			return str(id)
	return ""
