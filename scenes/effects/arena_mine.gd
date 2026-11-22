extends Node3D

## Mina del evento "Fábrica de minas". Parpadea mientras se arma, explota al
## acercarse o al agotar su vida y deja una onda de choque del color del evento.

const SLAM_WAVE_SCENE: PackedScene = preload("res://scenes/effects/slam_wave.tscn")

@export var arm_time: float = 0.9
@export var trigger_radius: float = 2.3
@export var explosion_radius: float = 3.4
@export var life_time: float = 7.0

var damage: float = 20.0
var color: Color = Color(1.0, 0.45, 0.12, 1.0)

var _armed: bool = false
var _arm_timer: float = 0.0
var _life_timer: float = 0.0
var _time: float = 0.0

@onready var _core: MeshInstance3D = $Core
@onready var _ring: MeshInstance3D = $Ring
@onready var _light: OmniLight3D = $Light


func _ready() -> void:
	_arm_timer = arm_time
	_life_timer = life_time
	_apply_style()


func start(mine_damage: float, blast_radius: float, accent: Color) -> void:
	damage = mine_damage
	explosion_radius = blast_radius
	color = accent
	_apply_style()


func _physics_process(delta: float) -> void:
	if not GameState.is_run_active:
		return

	_time += delta
	_arm_timer = maxf(_arm_timer - delta, 0.0)
	if _arm_timer <= 0.0:
		_armed = true
	_life_timer -= delta
	_update_visuals()

	var player: Node3D = _get_player()
	if _armed and player != null and _distance_to(player) <= trigger_radius:
		_explode()
		return
	if _life_timer <= 0.0:
		_explode()


func _update_visuals() -> void:
	var speed: float = 9.0 if _armed else 5.0
	var blink: float = 0.5 + 0.5 * sin(_time * speed)
	_light.light_energy = 0.4 + blink * 1.7
	_core.scale = Vector3.ONE * (1.0 + (0.14 if _armed else 0.05) * blink)
	_ring.rotation.y = _time * (3.0 if _armed else 1.4)


func _explode() -> void:
	var player: Node3D = _get_player()
	if player != null and _distance_to(player) <= explosion_radius:
		player.call("take_damage", damage)

	var wave: Node3D = SLAM_WAVE_SCENE.instantiate() as Node3D
	if wave != null and get_parent() != null:
		wave.set("color", color)
		get_parent().add_child(wave)
		wave.global_position = Vector3(global_position.x, 0.04, global_position.z)
		wave.call("start", explosion_radius)

	AudioDirector.play_event_destroy(global_position + Vector3.UP * 0.4)
	queue_free()


func _apply_style() -> void:
	var material: StandardMaterial3D = _make_material(color)
	_core.material_override = material
	_ring.material_override = material
	_light.light_color = color


func _make_material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 2.5
	return material


func _distance_to(target: Node3D) -> float:
	var offset: Vector3 = target.global_position - global_position
	offset.y = 0.0
	return offset.length()


func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D
