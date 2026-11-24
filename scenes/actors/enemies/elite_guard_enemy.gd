extends "res://scenes/actors/enemies/guard_enemy.gd"

## Élite guardia: además de cubrirse, embiste con el escudo. Marca la carga,
## arranca en línea recta y cierra con una onda de impacto.

const SLAM_WAVE_SCENE: PackedScene = preload("res://scenes/effects/slam_wave.tscn")

enum ChargeState { NONE, TELEGRAPH, CHARGE, RECOVER }

@export_group("Elite Charge")
@export var charge_interval: float = 5.0
@export var charge_range: float = 9.0
@export var charge_telegraph: float = 0.9
@export var charge_speed: float = 11.0
@export var charge_duration: float = 0.55
@export var charge_damage: float = 28.0
@export var charge_radius: float = 1.5
@export var charge_recover: float = 0.8
@export var charge_wave_radius: float = 2.4

var _charge_state: ChargeState = ChargeState.NONE
var _charge_timer: float = 0.0
var _charge_cooldown: float = 2.0
var _charge_direction: Vector3 = Vector3.ZERO
var _charge_hit: bool = false
var _charge_aura: OmniLight3D


func _ready() -> void:
	super._ready()
	add_to_group("elites")
	charge_damage *= (
		Settings.enemy_damage_multiplier()
		* GameState.contract_modifier("enemy_damage", 1.0)
		* GameState.cycle_enemy_damage_mult()
	)
	_charge_aura = get_node_or_null("Aura") as OmniLight3D
	EventBus.boss_spawned.emit(self, max_health)


func _physics_process(delta: float) -> void:
	if _charge_state == ChargeState.NONE:
		_charge_cooldown = maxf(_charge_cooldown - delta, 0.0)
		super._physics_process(delta)
		if _charge_cooldown <= 0.0 and not _guarding and _distance_to_player() <= charge_range:
			_begin_charge_telegraph()
		return

	_process_charge_state(delta)


func _process_charge_state(delta: float) -> void:
	match _charge_state:
		ChargeState.TELEGRAPH:
			velocity.x = 0.0
			velocity.z = 0.0
			_charge_timer -= delta
			_pulse_charge_shield(delta)
			_update_aura(_charge_timer / maxf(charge_telegraph, 0.01))
			if _charge_timer <= 0.0:
				_charge_state = ChargeState.CHARGE
				_charge_timer = charge_duration
				_charge_hit = false
				_play_anim("Attack", charge_duration)
		ChargeState.CHARGE:
			velocity.x = _charge_direction.x * charge_speed
			velocity.z = _charge_direction.z * charge_speed
			_pulse_charge_shield(delta)
			_update_aura(1.0)
			_charge_timer -= delta
			_check_charge_hit()
			if _charge_timer <= 0.0:
				_finish_charge()
		ChargeState.RECOVER:
			velocity.x = 0.0
			velocity.z = 0.0
			_charge_timer -= delta
			_update_aura(0.0)
			if _charge_timer <= 0.0:
				_charge_state = ChargeState.NONE

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_after_move_climb()


func _begin_charge_telegraph() -> void:
	_charge_state = ChargeState.TELEGRAPH
	_charge_timer = charge_telegraph
	velocity = Vector3.ZERO
	_set_guarding(false)

	var player: Node3D = _get_player()
	if player != null:
		_charge_direction = player.global_position - global_position
		_charge_direction.y = 0.0
		if _charge_direction.length_squared() < 0.01:
			_charge_direction = -global_transform.basis.z
		else:
			_charge_direction = _charge_direction.normalized()
	_face_direction(_charge_direction)
	_play_anim("Guard", charge_telegraph)
	if _shield != null:
		_shield.show()
		_shield.scale = _shield_base_scale
	if _charge_aura != null:
		_charge_aura.light_energy = 2.4


func _pulse_charge_shield(delta: float) -> void:
	if _shield == null:
		return
	_shield_pulse_time += delta
	var pulse: float = 1.0 + sin(_shield_pulse_time * 10.0) * 0.05
	_shield.scale = _shield_base_scale * pulse


func _finish_charge() -> void:
	_charge_state = ChargeState.RECOVER
	_charge_timer = charge_recover
	_charge_cooldown = charge_interval
	velocity = Vector3.ZERO
	_play_anim("Guard", charge_recover)
	if _shield != null:
		_shield.hide()
	_spawn_wave()
	if _charge_aura != null:
		_charge_aura.light_energy = 0.7


func _check_charge_hit() -> void:
	if _charge_hit:
		return
	var player: Node3D = _get_player()
	if player == null:
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > charge_radius:
		return
	_charge_hit = true
	if player.has_method("take_damage"):
		player.call("take_damage", charge_damage)


func _spawn_wave() -> void:
	var wave: Node3D = SLAM_WAVE_SCENE.instantiate() as Node3D
	if wave == null:
		return
	get_parent().add_child(wave)
	wave.global_position = Vector3(global_position.x, 0.03, global_position.z)
	wave.call("start", charge_wave_radius)


func _face_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.01:
		return
	look_at(global_position + direction, Vector3.UP)


func _distance_to_player() -> float:
	var player: Node3D = _get_player()
	if player == null:
		return 9999.0
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	return to_player.length()


func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _update_aura(charge: float) -> void:
	if _charge_aura == null:
		return
	_charge_aura.light_energy = lerpf(0.7, 2.6, clampf(charge, 0.0, 1.0))


func take_hit(
	hit_zone: String,
	base_damage: float,
	base_money: int,
	hit_position: Vector3 = Vector3.INF
) -> void:
	# Durante la embestida el escudo cubre el cuerpo; la cabeza sigue siendo
	# la ventana de daño real.
	if _charge_state == ChargeState.TELEGRAPH or _charge_state == ChargeState.CHARGE:
		if hit_zone != "head":
			base_damage *= 0.35
			base_money = int(base_money * 0.35)

	super.take_hit(hit_zone, base_damage, base_money, hit_position)
	if current_health > 0.0:
		EventBus.boss_health_changed.emit(current_health, max_health)
	else:
		EventBus.boss_defeated.emit()
