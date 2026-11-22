class_name WeaponData
extends Resource

## Datos de un arma. El jugador consume estas stats y el hub/árbol puede
## agregar bonus encima.

@export var weapon_name: String = "Rifle básico"
@export var description: String = "Arma equilibrada de fábrica."
@export var price: int = 0
@export var damage: float = 20.0
@export var money_per_hit: int = 10
@export var range: float = 100.0
@export var shots_per_second: float = 4.0
@export var magazine_size: int = 12
@export var ammo_regen_per_second: float = 3.0
@export var regen_delay: float = 0.25
## Si es false, hay que soltar y volver a hacer click para cada disparo.
@export var automatic: bool = true
