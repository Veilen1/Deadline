class_name WeaponRegistry
extends RefCounted

## Catálogo de armas disponibles en la tienda. El jugador equipa una y la
## usa al empezar la run.

const WEAPONS: Dictionary = {
	"basic_rifle": "res://resources/weapons/basic_rifle.tres",
	"smg": "res://resources/weapons/smg.tres",
	"shotgun": "res://resources/weapons/shotgun.tres",
}


static func ids() -> Array:
	return WEAPONS.keys()


static func has_weapon(weapon_id: String) -> bool:
	return WEAPONS.has(weapon_id)


static func get_data(weapon_id: String) -> WeaponData:
	if not WEAPONS.has(weapon_id):
		return null
	return load(WEAPONS[weapon_id]) as WeaponData
