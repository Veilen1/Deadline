extends Node3D

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Marker3D] = []


func _ready() -> void:
	if spawn_points.is_empty():
		_collect_spawn_points()


func spawn_wave(wave_number: int) -> void:
	# TODO: Fase 4 — oleadas, dificultad por zona y élite final.
	# Usar enemy_scene + spawn_points + EventBus.wave_started / wave_completed.
	pass


func _collect_spawn_points() -> void:
	# Fallback: si no se asignaron en el inspector, toma los Marker3D hijos.
	for child: Node in get_children():
		if child is Marker3D:
			spawn_points.append(child)
