extends Node3D

## Evento de arena destructible. Según `event_kind` pulsa daño, ralentiza al
## jugador o dispara proyectiles. Al destruirlo entrega núcleos extra.

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/effects/enemy_projectile.tscn")
const SLAM_WAVE_SCENE: PackedScene = preload("res://scenes/effects/slam_wave.tscn")

@export var event_kind: String = "pulse"
@export var title: String = "Reactor inestable"
@export var description: String = "Pulsa daño en el área."
@export var max_health: float = 150.0
@export var core_reward: int = 2
@export var radius: float = 6.0

@export_group("Pulse")
@export var pulse_damage: float = 8.0
@export var pulse_interval: float = 3.0

@export_group("Slow")
@export var slow_multiplier: float = 0.6
@export var slow_duration: float = 0.8
@export var slow_interval: float = 0.6

@export_group("Turret")
@export var projectile_damage: float = 14.0
@export var projectile_interval: float = 1.5
@export var projectile_speed: float = 20.0

@onready var _core: MeshInstance3D = $Core
@onready var _ring: MeshInstance3D = $Ring
@onready var _label: Label3D = $Label
@onready var _light: OmniLight3D = $Light

var current_health: float
var _timer: float = 0.0
var _time: float = 0.0
var _ring_base_scale: Vector3 = Vector3.ONE


func _ready() -> void:
	add_to_group("arena_events")
	max_health *= (
		GameState.cycle_enemy_health_mult() * GameState.contract_modifier("enemy_health", 1.0)
	)
	current_health = max_health
	_ring_base_scale = _ring.scale
	pulse_damage *= _enemy_damage_mult()
	projectile_damage *= _enemy_damage_mult()
	_timer = _initial_interval()
	_apply_style()
	_update_label()
	Toast.show_toast(
		"EVENTO DE ARENA",
		title,
		description,
		"Destruilo para +%d ◈" % core_reward,
		_accent()
	)


func _physics_process(delta: float) -> void:
	if not GameState.is_run_active:
		return

	_time += delta
	_timer -= delta
	_update_visuals()

	if _timer <= 0.0:
		_timer = _interval()
		_trigger()


func _trigger() -> void:
	var player: Node3D = _get_player()
	if player == null:
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var distance: float = to_player.length()

	match event_kind:
		"pulse":
			if distance <= radius:
				player.call("take_damage", pulse_damage)
				_spawn_wave()
		"slow":
			if distance <= radius:
				player.call("apply_slow", slow_multiplier, slow_duration)
				_spawn_wave()
		"turret":
			if distance <= 26.0:
				_fire_at(player)
		_:
			if distance <= radius:
				player.call("take_damage", pulse_damage)
				_spawn_wave()


func _fire_at(player: Node3D) -> void:
	var target: Vector3 = player.global_position + Vector3.UP * 1.0
	var direction: Vector3 = (target - global_position).normalized()
	var origin: Vector3 = global_position + Vector3.UP * 1.9 + direction * 0.9
	var projectile: Node3D = PROJECTILE_SCENE.instantiate() as Node3D
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.call("launch", origin, target, projectile_speed, projectile_damage, 3.5, self)


func _spawn_wave() -> void:
	var wave: Node3D = SLAM_WAVE_SCENE.instantiate() as Node3D
	if wave == null:
		return
	wave.set("color", _accent())
	get_parent().add_child(wave)
	wave.global_position = Vector3(global_position.x, 0.04, global_position.z)
	wave.call("start", radius)


func take_hit(
	_hit_zone: String,
	base_damage: float,
	_base_money: int,
	_hit_position: Vector3 = Vector3.INF
) -> void:
	if current_health <= 0.0:
		return
	current_health -= base_damage
	_update_label()
	_flash()

	if current_health <= 0.0:
		_destroy()


func _destroy() -> void:
	GameState.add_cores(core_reward)
	Toast.show_toast(
		"EVENTO COMPLETADO",
		title,
		"La arena queda un poco más tranquila.",
		"+%d ◈" % core_reward,
		_accent()
	)
	AudioDirector.play_upgrade()
	queue_free()


func _update_label() -> void:
	_label.text = "%s\n%d / %d" % [title, int(ceil(current_health)), int(max_health)]


func _flash() -> void:
	_label.modulate = Color(1, 1, 1, 1)
	_light.light_energy = 3.0
	var tween: Tween = create_tween()
	tween.tween_property(_label, "modulate", _accent(), 0.15)
	tween.parallel().tween_property(_light, "light_energy", 0.8, 0.15)


func _update_visuals() -> void:
	var pulse: float = 1.0 + sin(_time * 6.0) * 0.06
	_ring.scale = Vector3(
		_ring_base_scale.x * pulse, _ring_base_scale.y, _ring_base_scale.z * pulse
	)
	_label.position.y = 3.1 + sin(_time * 2.4) * 0.06


func _apply_style() -> void:
	var accent: Color = _accent()
	_core.material_override = _make_material(accent)
	_ring.material_override = _make_material(accent)
	_label.modulate = accent
	_light.light_color = accent


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	return material


func _accent() -> Color:
	match event_kind:
		"slow":
			return Color(0.3, 0.8, 1.0, 1)
		"turret":
			return Color(1.0, 0.55, 0.15, 1)
		_:
			return Color(1.0, 0.16, 0.1, 1)


func _initial_interval() -> float:
	match event_kind:
		"slow":
			return slow_interval
		"turret":
			return maxf(projectile_interval, 2.0)
		_:
			return maxf(pulse_interval, 2.5)


func _interval() -> float:
	match event_kind:
		"slow":
			return slow_interval
		"turret":
			return projectile_interval
		_:
			return pulse_interval


func _enemy_damage_mult() -> float:
	return (
		Settings.enemy_damage_multiplier()
		* GameState.cycle_enemy_damage_mult()
		* GameState.contract_modifier("enemy_damage", 1.0)
	)


func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D
