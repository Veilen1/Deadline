extends Node3D

# Oleadas de la zona. Cada vez que muere un enemigo se descuenta del conteo;
# al limpiar la última oleada se completa la zona.

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Marker3D] = []
@export var enemies_per_wave: Array[int] = [4, 5, 6]
@export var wave_delay: float = 2.5
@export var completion_bonus: int = 50

var current_wave: int = 0
var _alive_enemies: int = 0


func _ready() -> void:
	if spawn_points.is_empty():
		_collect_spawn_points()

	EventBus.enemy_killed.connect(_on_enemy_killed)
	# Diferido: main ya hizo start_run y conectó las señales del HUD.
	_start_wave.call_deferred()


func _start_wave() -> void:
	if not GameState.is_run_active or current_wave >= enemies_per_wave.size():
		return
	if enemy_scene == null or spawn_points.is_empty():
		push_warning("Zone01: falta enemy_scene o spawn_points")
		return

	current_wave += 1
	_alive_enemies = enemies_per_wave[current_wave - 1]
	EventBus.wave_started.emit(current_wave)

	for index in _alive_enemies:
		_spawn_enemy(index)


func _spawn_enemy(index: int) -> void:
	var point: Marker3D = spawn_points[index % spawn_points.size()]
	var enemy: Node3D = enemy_scene.instantiate()
	add_child(enemy)

	# Si hay más enemigos que puntos, se abren en anillos para no apilarse.
	var ring: int = int(floor(float(index) / float(spawn_points.size())))
	var angle: float = float(index) * TAU / float(spawn_points.size())
	var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * (0.8 * float(ring))
	enemy.global_position = point.global_position + offset


func _on_enemy_killed(_enemy: Node, _hit_zone: String) -> void:
	if not GameState.is_run_active:
		return

	_alive_enemies = maxi(_alive_enemies - 1, 0)
	if _alive_enemies > 0:
		return

	EventBus.wave_completed.emit(current_wave)

	if current_wave >= enemies_per_wave.size():
		_finish_zone()
		return

	await get_tree().create_timer(wave_delay).timeout
	if GameState.is_run_active:
		_start_wave()


func _finish_zone() -> void:
	GameState.add_money(completion_bonus)
	GameState.end_run("completed")


func _collect_spawn_points() -> void:
	# Fallback: si no se asignaron en el inspector, toma los Marker3D hijos.
	for child: Node in get_children():
		if child is Marker3D:
			spawn_points.append(child)
