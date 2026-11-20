extends "res://scenes/actors/enemies/enemy_base.gd"

## Élite de zona: camina lento y salta hacia el jugador. Antes de saltar marca
## la zona de impacto en el piso y espera el tiempo suficiente para salir.

const JUMP_TARGET_SCENE: PackedScene = preload("res://scenes/effects/jump_target.tscn")
const SLAM_WAVE_SCENE: PackedScene = preload("res://scenes/effects/slam_wave.tscn")

enum State { CHASE, TELEGRAPH, JUMP, RECOVER }

@export_group("Elite Jump")
@export var jump_interval: float = 3.0
@export var jump_trigger_range: float = 12.0
@export var jump_radius: float = 3.5
@export var jump_damage: float = 36.0
@export var jump_height: float = 3.0
@export var air_time: float = 0.55
@export var recover_time: float = 0.5
@export var reaction_time: float = 0.4
@export var escape_safety_factor: float = 1.2
@export var min_telegraph_time: float = 1.5
@export var aura_idle_energy: float = 0.7
@export var aura_charge_energy: float = 3.0

var _state: State = State.CHASE
var _state_timer: float = 0.0
var _cooldown: float = 1.0
var _jump_start: Vector3
var _jump_target: Vector3
var _telegraph_time: float = 1.5
var _target_indicator: Node3D
var _aura: OmniLight3D


func _ready() -> void:
	super._ready()
	add_to_group("elites")
	jump_damage *= (
		Settings.enemy_damage_multiplier()
		* GameState.contract_modifier("enemy_damage", 1.0)
		* GameState.cycle_enemy_damage_mult()
	)
	_aura = get_node_or_null("Aura") as OmniLight3D
	EventBus.boss_spawned.emit(self, max_health)


func take_hit(hit_zone: String, base_damage: float, base_money: int, hit_position: Vector3 = Vector3.INF) -> void:
	super.take_hit(hit_zone, base_damage, base_money, hit_position)

	if current_health > 0.0:
		EventBus.boss_health_changed.emit(current_health, max_health)
	else:
		EventBus.boss_defeated.emit()


func _physics_process(delta: float) -> void:
	_update_aura()

	var player: Node3D = _get_player()

	match _state:
		State.JUMP:
			_process_jump(delta)
			return
		State.CHASE:
			_process_chase(delta, player)
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.RECOVER:
			_process_recover(delta)

	if _state == State.JUMP:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _process_chase(delta: float, player: Node3D) -> void:
	if player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var distance: float = to_player.length()

	var direction: Vector3 = to_player.normalized() if distance > 0.01 else Vector3.ZERO
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown <= 0.0 and distance <= jump_trigger_range:
		_begin_telegraph(player)


func _begin_telegraph(player: Node3D) -> void:
	_state = State.TELEGRAPH
	velocity = Vector3.ZERO
	_cooldown = jump_interval
	_telegraph_time = _compute_telegraph_time()
	_state_timer = _telegraph_time

	var target: Vector3 = player.global_position
	_jump_target = Vector3(target.x, global_position.y, target.z)
	_spawn_target_indicator(target)


func _process_telegraph(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer -= delta
	if _state_timer <= 0.0:
		_start_jump()


func _start_jump() -> void:
	_state = State.JUMP
	_state_timer = 0.0
	_jump_start = global_position


func _process_jump(delta: float) -> void:
	_state_timer += delta
	var t: float = clampf(_state_timer / maxf(air_time, 0.01), 0.0, 1.0)

	var position: Vector3 = _jump_start.lerp(_jump_target, t)
	position.y = lerpf(_jump_start.y, _jump_target.y, t) + sin(t * PI) * jump_height
	global_position = position

	if t >= 1.0:
		_land()


func _land() -> void:
	global_position = _jump_target
	_state = State.RECOVER
	_state_timer = recover_time
	velocity = Vector3.ZERO

	_free_target_indicator()
	_spawn_slam_wave()
	_damage_player_in_radius()


func _process_recover(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer -= delta
	if _state_timer <= 0.0:
		_state = State.CHASE


func _compute_telegraph_time() -> float:
	var player_speed: float = 5.0
	var player: Node3D = _get_player()
	if player != null:
		player_speed = float(player.get("move_speed"))

	# Tiempo mínimo para cruzar el radio desde el centro + reacción.
	var time_to_clear: float = jump_radius / maxf(player_speed, 0.1)
	return maxf(min_telegraph_time, time_to_clear * escape_safety_factor + reaction_time)


func _spawn_target_indicator(target_position: Vector3) -> void:
	_free_target_indicator()
	_target_indicator = JUMP_TARGET_SCENE.instantiate() as Node3D
	if _target_indicator == null:
		return
	get_parent().add_child(_target_indicator)
	_target_indicator.global_position = Vector3(target_position.x, 0.03, target_position.z)
	_target_indicator.call("start", jump_radius, _telegraph_time + air_time)


func _spawn_slam_wave() -> void:
	var wave: Node3D = SLAM_WAVE_SCENE.instantiate() as Node3D
	if wave == null:
		return
	get_parent().add_child(wave)
	wave.global_position = Vector3(global_position.x, 0.03, global_position.z)
	wave.call("start", jump_radius)


func _damage_player_in_radius() -> void:
	var player: Node3D = _get_player()
	if player == null:
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() <= jump_radius and player.has_method("take_damage"):
		player.call("take_damage", jump_damage)


func _free_target_indicator() -> void:
	if is_instance_valid(_target_indicator):
		_target_indicator.queue_free()
	_target_indicator = null


func _update_aura() -> void:
	if _aura == null:
		return

	var charge: float = 0.0
	if _state == State.TELEGRAPH:
		charge = 1.0 - clampf(_state_timer / maxf(_telegraph_time, 0.01), 0.0, 1.0)
	elif _state == State.JUMP:
		charge = 1.0

	_aura.light_energy = lerpf(aura_idle_energy, aura_charge_energy, charge)


func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _exit_tree() -> void:
	_free_target_indicator()
