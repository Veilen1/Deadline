extends Node3D

# Oleadas de la zona. Cada vez que muere un enemigo se descuenta del conteo;
# al limpiar la última oleada se completa la zona.

const SPAWN_TELEGRAPH_SCENE: PackedScene = preload("res://scenes/effects/spawn_telegraph.tscn")

@export var enemy_scene: PackedScene
@export var enemy_scenes: Array[PackedScene] = []
@export var elite_scene: PackedScene
@export var spawn_points: Array[Marker3D] = []
@export var enemies_per_wave: Array[int] = [4, 5, 3]
@export var wave_delay: float = 0.8
@export var completion_bonus: int = 35
@export var spawn_telegraph_time: float = 2.0
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

	var entries: Array[Dictionary] = []
	for index in regular_count:
		var scene: PackedScene = _pick_enemy_scene(index)
		if scene != null:
			entries.append({"index": index, "scene": scene, "elite": false})
	if spawn_elite:
		entries.append({"index": regular_count, "scene": elite_scene, "elite": true})

	# Primero se marcan los puntos de aparición; los enemigos salen 2 s después.
	_show_spawn_telegraphs(entries)
	await get_tree().create_timer(spawn_telegraph_time, false).timeout
	if not GameState.is_run_active or _completed:
		return

	for entry in entries:
		if bool(entry.get("elite", false)):
			_spawn_elite()
		else:
			_spawn_enemy_entry(int(entry.get("index", 0)), entry.get("scene") as PackedScene)


func _show_spawn_telegraphs(entries: Array[Dictionary]) -> void:
	for entry in entries:
		var is_elite: bool = bool(entry.get("elite", false))
		var scene: PackedScene = entry.get("scene") as PackedScene
		var world_position: Vector3
		if is_elite:
			world_position = spawn_points[0].global_position + Vector3(0.8, 0.0, 0.0)
		else:
			world_position = _spawn_position(int(entry.get("index", 0)))

		var info: Dictionary = _telegraph_info(scene, is_elite)
		_spawn_telegraph(
			world_position,
			str(info.get("label", "ENEMIGO")),
			info.get("color", Color(1, 0.2, 0.12, 1)),
			is_elite
		)


func _spawn_telegraph(
	world_position: Vector3, label: String, accent: Color, is_elite: bool
) -> void:
	var telegraph: Node3D = SPAWN_TELEGRAPH_SCENE.instantiate() as Node3D
	if telegraph == null:
		return
	telegraph.set("enemy_label", label)
	telegraph.set("accent_color", accent)
	telegraph.set("is_elite", is_elite)
	add_child(telegraph)
	telegraph.global_position = Vector3(world_position.x, 0.03, world_position.z)
	telegraph.call("start", spawn_telegraph_time)


func _telegraph_info(scene: PackedScene, is_elite: bool) -> Dictionary:
	if is_elite:
		return {"label": "ÉLITE", "color": Color(1.0, 0.85, 0.3, 1)}
	if scene == null:
		return {"label": "ENEMIGO", "color": Color(1.0, 0.3, 0.25, 1)}

	match String(scene.resource_path).get_file():
		"guard_enemy.tscn":
			return {"label": "GUARDIA", "color": Color(0.35, 1.0, 0.55, 1)}
		"ranged_enemy.tscn":
			return {"label": "TIRADOR", "color": Color(0.78, 0.55, 1.0, 1)}
		"hound_enemy.tscn":
			return {"label": "SABUESO", "color": Color(1.0, 0.62, 0.18, 1)}
		_:
			return {"label": "BÁSICO", "color": Color(1.0, 0.3, 0.25, 1)}


func _spawn_enemy_entry(index: int, scene: PackedScene) -> void:
	if scene == null:
		return
	var enemy: Node3D = scene.instantiate()
	add_child(enemy)
	# Compensa el origen de la cápsula cuando el enemigo tiene escala distinta de 1.
	var height_offset: float = (enemy.scale.y - 1.0) * 0.9
	enemy.global_position = _spawn_position(index) + Vector3(0.0, height_offset, 0.0)


func _spawn_position(index: int) -> Vector3:
	var point: Marker3D = spawn_points[index % spawn_points.size()]
	# Si hay más enemigos que puntos, se abren en anillos para no apilarse.
	var ring: int = int(floor(float(index) / float(spawn_points.size())))
	var angle: float = float(index) * TAU / float(spawn_points.size())
	var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * (0.8 * float(ring))
	return point.global_position + offset


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
	GameState.register_zone_cleared()
	EventBus.zone_completed.emit(zone_id)


func _collect_spawn_points() -> void:
	# Fallback: si no se asignaron en el inspector, toma los Marker3D hijos.
	for child: Node in get_children():
		if child is Marker3D:
			spawn_points.append(child)
