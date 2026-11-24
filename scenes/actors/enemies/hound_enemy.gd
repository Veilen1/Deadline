extends "res://scenes/actors/enemies/enemy_base.gd"

## Sabueso explosivo: corre directo al jugador y detona al acercarse.
## La luz roja avisa la mecha; si lo matás antes, no explota.

const SLAM_WAVE_SCENE: PackedScene = preload("res://scenes/effects/slam_wave.tscn")

enum State { CHASE, FUSE }

@export_group("Sabueso")
@export var fuse_range: float = 2.6
@export var fuse_time: float = 0.45
@export var explosion_radius: float = 3.0
@export var explosion_damage: float = 26.0
@export var fuse_pulse_speed: float = 18.0

var _state: State = State.CHASE
var _fuse_timer: float = 0.0
var _fuse_glow: MeshInstance3D
var _fuse_scale: float = 1.0


func _ready() -> void:
	super._ready()
	explosion_damage *= (
		Settings.enemy_damage_multiplier()
		* GameState.contract_modifier("enemy_damage", 1.0)
		* GameState.cycle_enemy_damage_mult()
	)
	_fuse_glow = get_node_or_null("FuseGlow") as MeshInstance3D
	if _fuse_glow != null:
		_fuse_glow.hide()


func _physics_process(delta: float) -> void:
	if current_health <= 0.0:
		return

	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_vertical(delta)
		move_and_slide()
		_after_move_climb()
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var distance: float = to_player.length()
	var direction: Vector3 = to_player.normalized() if distance > 0.01 else Vector3.ZERO
	_face_player(player)

	if _state == State.FUSE:
		velocity.x = 0.0
		velocity.z = 0.0
		_fuse_timer -= delta
		_update_fuse()
		_play_anim("Fuse", 0.2)
		if _fuse_timer <= 0.0:
			_explode(player)
			return
	else:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		_play_anim("Run")
		if distance <= fuse_range:
			_start_fuse()

	_apply_vertical(delta)
	move_and_slide()
	_after_move_climb()


func _start_fuse() -> void:
	_state = State.FUSE
	_fuse_timer = fuse_time
	if _fuse_glow != null:
		_fuse_glow.show()
		_fuse_scale = 1.0


func _update_fuse() -> void:
	if _fuse_glow == null:
		return
	var elapsed: float = 1.0 - clampf(_fuse_timer / maxf(fuse_time, 0.01), 0.0, 1.0)
	var pulse: float = 1.0 + sin(elapsed * fuse_pulse_speed) * 0.12
	_fuse_glow.scale = Vector3.ONE * lerpf(0.8, 1.8, elapsed) * pulse


func _explode(player: Node3D) -> void:
	_spawn_wave()

	if player != null:
		var to_player: Vector3 = player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() <= explosion_radius and player.has_method("take_damage"):
			player.call("take_damage", explosion_damage)

	# Cuenta como baja para que la oleada avance aunque se autodestruya.
	EventBus.enemy_killed.emit(self, "torso")
	queue_free()


func _spawn_wave() -> void:
	var wave: Node3D = SLAM_WAVE_SCENE.instantiate() as Node3D
	if wave == null:
		return
	get_parent().add_child(wave)
	wave.global_position = Vector3(global_position.x, 0.03, global_position.z)
	wave.call("start", explosion_radius)
