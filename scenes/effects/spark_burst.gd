extends CPUParticles3D

## Chispas de impacto crítico. Se autodestruyen después de emitir.

func start(world_position: Vector3, critical: bool) -> void:
	global_position = world_position
	color = Color(1.0, 0.8, 0.2, 1.0) if critical else Color(0.3, 0.85, 1.0, 1.0)
	emitting = true

	await get_tree().create_timer(lifetime + 0.25, false).timeout
	queue_free()
