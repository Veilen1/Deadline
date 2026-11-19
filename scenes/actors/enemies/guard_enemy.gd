extends "res://scenes/actors/enemies/enemy_base.gd"

## Enemigo verde de Zona 2: alterna entre perseguir y cubrirse con un escudo.
## Mientras se cubre no se mueve ni ataca, y recibe mucho menos daño salvo en la cabeza.

@export_group("Guard")
@export var guard_interval: float = 2.5
@export var guard_duration: float = 1.2
@export var guard_damage_multiplier: float = 0.25
@export var guard_money_multiplier: float = 0.25
@export var shield_pulse_speed: float = 6.0
@export var shield_pulse_amount: float = 0.03

var _guarding: bool = false
var _guard_timer: float = 0.0
var _shield: MeshInstance3D
var _shield_base_scale: Vector3 = Vector3.ONE
var _shield_pulse_time: float = 0.0


func _ready() -> void:
	super._ready()
	_shield = get_node_or_null("Shield") as MeshInstance3D
	if _shield != null:
		_shield_base_scale = _shield.scale
		_shield.hide()
	_guard_timer = randf_range(guard_interval * 0.5, guard_interval)


func _physics_process(delta: float) -> void:
	_guard_timer -= delta

	if _guarding:
		_process_guard(delta)
		if _guard_timer <= 0.0:
			_set_guarding(false)
		return

	super._physics_process(delta)
	if _guard_timer <= 0.0:
		_set_guarding(true)


func _process_guard(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()

	if _shield == null:
		return
	_shield_pulse_time += delta
	var pulse: float = 1.0 + sin(_shield_pulse_time * shield_pulse_speed) * shield_pulse_amount
	_shield.scale = _shield_base_scale * pulse


func _set_guarding(value: bool) -> void:
	_guarding = value
	_shield_pulse_time = 0.0
	if _shield != null:
		_shield.visible = value
		_shield.scale = _shield_base_scale
	_guard_timer = guard_duration if value else guard_interval


func take_hit(hit_zone: String, base_damage: float, base_money: int, hit_position: Vector3 = Vector3.INF) -> void:
	# La cabeza ignora el escudo: premia la puntería.
	if _guarding and hit_zone != "head":
		base_damage *= guard_damage_multiplier
		base_money = int(base_money * guard_money_multiplier)

	super.take_hit(hit_zone, base_damage, base_money, hit_position)
