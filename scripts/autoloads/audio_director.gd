extends Node

## Director de audio global: música ambiente en loop y sonidos de combate
## posicionales disparados por eventos. Respeta el volumen master de Settings.

@export var ambient_volume_db: float = -22.0
@export var combat_volume_db: float = -17.0
@export var hit_volume_db: float = -14.0
@export var crit_volume_db: float = -10.0
@export var kill_volume_db: float = -11.0
@export var hurt_volume_db: float = -12.0
@export var max_fx_players: int = 16
@export var hit_min_interval_ms: int = 45

var _ambient_players: Array[AudioStreamPlayer] = []
var _ambient_streams: Array[AudioStream] = []
var _ambient_active: int = 0
var _ambient_tween: Tween
var _combat_layer: AudioStreamPlayer
var _combat_tween: Tween
var _hurt_player: AudioStreamPlayer
var _upgrade_player: AudioStreamPlayer
var _hit_stream: AudioStream
var _crit_stream: AudioStream
var _kill_stream: AudioStream
var _hurt_stream: AudioStream
var _enemy_shot_stream: AudioStream
var _event_spawn_stream: AudioStream
var _event_destroy_stream: AudioStream

var _fx_players: Array[AudioStreamPlayer3D] = []
var _last_hit_ms: int = 0
var _last_crit_ms: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_ambient_streams = [
		preload("res://assets/audio/ambient_loop.wav"),
		preload("res://assets/audio/ambient_cold_loop.wav"),
		preload("res://assets/audio/ambient_dark_loop.wav"),
	]
	for index in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = ambient_volume_db if index == 0 else -60.0
		if index == 0:
			player.stream = _ambient_streams[0]
		add_child(player)
		_ambient_players.append(player)
	_ambient_players[0].play()

	_combat_layer = AudioStreamPlayer.new()
	_combat_layer.stream = preload("res://assets/audio/ambient_combat_loop.wav")
	_combat_layer.bus = "Music"
	_combat_layer.volume_db = -60.0
	add_child(_combat_layer)
	_combat_layer.play()

	_hit_stream = preload("res://assets/audio/hit.wav")
	_crit_stream = preload("res://assets/audio/crit.wav")
	_kill_stream = preload("res://assets/audio/kill.wav")
	_hurt_stream = preload("res://assets/audio/hurt.wav")
	_enemy_shot_stream = preload("res://assets/audio/enemy_shot.wav")
	_event_spawn_stream = preload("res://assets/audio/event_spawn.wav")
	_event_destroy_stream = preload("res://assets/audio/event_destroy.wav")

	_hurt_player = AudioStreamPlayer.new()
	_hurt_player.stream = _hurt_stream
	_hurt_player.volume_db = hurt_volume_db
	_hurt_player.bus = "SFX"
	add_child(_hurt_player)

	_upgrade_player = AudioStreamPlayer.new()
	_upgrade_player.stream = preload("res://assets/audio/level_up.wav")
	_upgrade_player.volume_db = -10.0
	_upgrade_player.bus = "SFX"
	add_child(_upgrade_player)

	EventBus.damage_number_requested.connect(_on_hit)
	EventBus.critical_hit.connect(_on_crit)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	GameState.run_started.connect(_on_run_started)
	GameState.run_ended.connect(_on_run_ended)


func _on_hit(world_position: Vector3, _amount: float) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_hit_ms < hit_min_interval_ms:
		return
	_last_hit_ms = now
	_play_at(_hit_stream, world_position, hit_volume_db, randf_range(0.92, 1.08))


func _on_crit(world_position: Vector3, _damage: float) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_crit_ms < hit_min_interval_ms:
		return
	_last_crit_ms = now
	_play_at(_crit_stream, world_position, crit_volume_db, randf_range(0.97, 1.05))


func _on_enemy_killed(enemy: Node, _hit_zone: String) -> void:
	var position: Vector3 = Vector3.ZERO
	if enemy is Node3D and is_instance_valid(enemy):
		position = (enemy as Node3D).global_position + Vector3.UP * 1.2
	_play_at(_kill_stream, position, kill_volume_db, randf_range(0.93, 1.05))


func _on_player_damaged(_amount: float) -> void:
	_hurt_player.pitch_scale = randf_range(0.94, 1.04)
	_hurt_player.play()


func play_upgrade() -> void:
	_upgrade_player.pitch_scale = randf_range(0.99, 1.03)
	_upgrade_player.play()


func play_enemy_shot(world_position: Vector3) -> void:
	_play_at(
		_enemy_shot_stream, world_position, -13.0, randf_range(0.92, 1.06)
	)


func play_event_spawn(world_position: Vector3) -> void:
	_play_at(_event_spawn_stream, world_position, -9.0, 1.0)


func play_event_destroy(world_position: Vector3) -> void:
	_play_at(_event_destroy_stream, world_position, -6.0, 1.0)


func set_zone_mood(zone_index: int) -> void:
	var index: int = clampi(zone_index, 0, 2)
	var boosts: Array[float] = [0.0, 0.5, 1.0]
	_crossfade_ambient(_ambient_streams[index], ambient_volume_db + boosts[index])


func reset_mood() -> void:
	_crossfade_ambient(_ambient_streams[0], ambient_volume_db)
	_set_combat(false)


func _crossfade_ambient(stream: AudioStream, target_db: float) -> void:
	if stream == null or _ambient_players.is_empty():
		return
	if _ambient_tween != null and _ambient_tween.is_valid():
		_ambient_tween.kill()

	var current: AudioStreamPlayer = _ambient_players[_ambient_active]
	for index in _ambient_players.size():
		if index == _ambient_active:
			continue
		_ambient_players[index].stop()
		_ambient_players[index].stream = null

	if current.stream == stream:
		_ambient_tween = create_tween()
		_ambient_tween.tween_property(current, "volume_db", target_db, 0.4)
		return

	var next_index: int = 1 - _ambient_active
	var next: AudioStreamPlayer = _ambient_players[next_index]
	next.stream = stream
	next.volume_db = -60.0
	next.play()

	_ambient_tween = create_tween()
	_ambient_tween.set_parallel(true)
	_ambient_tween.tween_property(current, "volume_db", -60.0, 0.6)
	_ambient_tween.tween_property(next, "volume_db", target_db, 0.6)
	_ambient_tween.set_parallel(false)
	_ambient_tween.tween_callback(
		func() -> void:
			current.stop()
			_ambient_active = next_index
	)


func _set_combat(active: bool) -> void:
	if _combat_layer == null:
		return
	if _combat_tween != null and _combat_tween.is_valid():
		_combat_tween.kill()
	_combat_tween = create_tween()
	_combat_tween.tween_property(
		_combat_layer,
		"volume_db",
		combat_volume_db if active else -60.0,
		0.5 if active else 1.0
	)


func _on_wave_started(_wave_number: int) -> void:
	_set_combat(true)


func _on_wave_completed(_wave_number: int) -> void:
	_set_combat(false)


func _on_run_started() -> void:
	_set_combat(false)


func _on_run_ended(_reason: String) -> void:
	_set_combat(false)


func _exit_tree() -> void:
	# Evita que los streams queden en uso al cerrar el juego.
	for player in _ambient_players:
		player.stop()
		player.stream = null
	if _combat_layer != null:
		_combat_layer.stop()
		_combat_layer.stream = null
	for player in _fx_players:
		if is_instance_valid(player):
			player.stop()


func _play_at(stream: AudioStream, world_position: Vector3, volume_db: float, pitch: float) -> void:
	if stream == null:
		return
	var scene: Node = get_tree().current_scene
	if scene == null or not is_instance_valid(scene):
		return

	_cleanup_players()

	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.unit_size = 14.0
	player.max_distance = 70.0
	player.bus = "SFX"
	scene.add_child(player)
	player.global_position = world_position
	player.play()
	player.finished.connect(player.queue_free)
	_fx_players.append(player)


func _cleanup_players() -> void:
	var alive: Array[AudioStreamPlayer3D] = []
	for player in _fx_players:
		if is_instance_valid(player):
			alive.append(player)
	_fx_players = alive

	# Si se acumulan demasiados, libera los más viejos.
	while _fx_players.size() >= max_fx_players:
		var oldest: AudioStreamPlayer3D = _fx_players.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
