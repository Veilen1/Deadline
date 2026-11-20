extends Node3D

# Oleadas de la zona. Cada vez que muere un enemigo se descuenta del conteo;
# al limpiar la última oleada se completa la zona.

@export var enemy_scene: PackedScene
@export var enemy_scenes: Array[PackedScene] = []
@export var elite_scene: PackedScene
@export var spawn_points: Array[Marker3D] = []
@export var enemies_per_wave: Array[int] = [4, 5, 3]
@export var wave_delay: float = 0.8
@export var completion_bonus: int = 35
@export var zone_id: String = "zona_1"

var current_wave: int = 0
var _alive_enemies: int = 0
var _completed: bool = false


func _ready() -> void:
	if spawn_points.is_empty():
		_collect_spawn_points()

	EventBus.enemy_killed.connect(_on_enemy_killed)
	# Diferido: main ya hizo start_run y conectó las señales del HUD.
	_start_wave.call_deferred()


func _start_wave() -> void:
	if _completed or not GameState.is_run_active or current_wave >= enemies_per_wave.size():
		return
	if (enemy_scene == null and enemy_scenes.is_empty()) or spawn_points.is_empty():
		push_warning("Zone: falta enemy_scene o spawn_points")
		return

	current_wave += 1

	# La última oleada suma al élite de la zona.
	var regular_count: int = enemies_per_wave[current_wave - 1]
	var spawn_elite: bool = elite_scene != null and current_wave == enemies_per_wave.size()
	_alive_enemies = regular_count + (1 if spawn_elite else 0)
	EventBus.wave_started.emit(current_wave)

	for index in regular_count:
		_spawn_enemy(index)

	if spawn_elite:
		_spawn_elite()


func _spawn_enemy(index: int) -> void:
	var point: Marker3D = spawn_points[index % spawn_points.size()]
	var scene: PackedScene = _pick_enemy_scene(index)
	if scene == null:
		return
	var enemy: Node3D = scene.instantiate()
	add_child(enemy)

	# Si hay más enemigos que puntos, se abren en anillos para no apilarse.
	var ring: int = int(floor(float(index) / float(spawn_points.size())))
	var angle: float = float(index) * TAU / float(spawn_points.size())
	var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * (0.8 * float(ring))
	# Compensa el origen de la cápsula cuando el enemigo tiene escala distinta de 1.
	var height_offset: float = (enemy.scale.y - 1.0) * 0.9
	enemy.global_position = point.global_position + offset + Vector3(0.0, height_offset, 0.0)


func _pick_enemy_scene(index: int) -> PackedScene:
	# Mezcla explícita por oleada cuando la zona define varias variantes.
	if not enemy_scenes.is_empty():
		return enemy_scenes[index % enemy_scenes.size()]
	return enemy_scene


func _spawn_elite() -> void:
	if elite_scene == null or spawn_points.is_empty():
		return

	var elite: Node3D = elite_scene.instantiate()
	add_child(elite)
	var height_offset: float = (elite.scale.y - 1.0) * 0.9
	elite.global_position = spawn_points[0].global_position + Vector3(0.0, height_offset, 0.0)


func _on_enemy_killed(_enemy: Node, _hit_zone: String) -> void:
	if _completed or not GameState.is_run_active:
		return

	_alive_enemies = maxi(_alive_enemies - 1, 0)
	if _alive_enemies > 0:
		return

	EventBus.wave_completed.emit(current_wave)

	if current_wave >= enemies_per_wave.size():
		_finish_zone()
		return

	await get_tree().create_timer(wave_delay, false).timeout
	if GameState.is_run_active and not _completed:
		_start_wave()


func _finish_zone() -> void:
	if _completed:
		return
	_completed = true
	GameState.add_money(completion_bonus)
	EventBus.zone_completed.emit(zone_id)


func _collect_spawn_points() -> void:
	# Fallback: si no se asignaron en el inspector, toma los Marker3D hijos.
	for child: Node in get_children():
		if child is Marker3D:
			spawn_points.append(child)
