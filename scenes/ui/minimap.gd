extends Control

## Radar centrado en el jugador. El jugador apunta siempre hacia arriba y el
## mundo rota con su yaw. Información táctica, poco llamativa.

@export var radar_range: float = 30.0
@export var margin: float = 6.0

@export_group("Colors")
@export var background_color: Color = Color(0.06, 0.08, 0.1, 0.68)
@export var border_color: Color = Color(1, 1, 1, 0.35)
@export var ring_color: Color = Color(1, 1, 1, 0.12)
@export var player_color: Color = Color(1, 1, 1, 0.95)
@export var enemy_color: Color = Color(0.95, 0.25, 0.15, 1)
@export var guard_color: Color = Color(0.25, 0.95, 0.45, 1)
@export var elite_color: Color = Color(1, 0.8, 0.2, 1)
@export var powerup_color: Color = Color(0.3, 0.8, 1, 1)
@export var event_color: Color = Color(1.0, 0.6, 0.2, 1)

@export_group("Markers")
@export var enemy_size: float = 5.5
@export var elite_size: float = 8.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - margin
	if radius <= 0.0:
		return

	draw_circle(center, radius, background_color)
	draw_arc(center, radius, 0.0, TAU, 64, border_color, 1.5)
	draw_arc(center, radius * 0.5, 0.0, TAU, 48, ring_color, 1.0)
	draw_line(center - Vector2(radius, 0.0), center + Vector2(radius, 0.0), ring_color, 1.0)
	draw_line(center - Vector2(0.0, radius), center + Vector2(0.0, radius), ring_color, 1.0)

	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	_draw_enemies(player, center, radius)
	_draw_powerups(player, center, radius)
	_draw_events(player, center, radius)
	_draw_player(center)


func _draw_enemies(player: Node3D, center: Vector2, radius: float) -> void:
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node3D:
			continue

		var marker_position: Vector2 = _to_radar((enemy as Node3D).global_position, player, center, radius)
		var is_elite: bool = (enemy as Node3D).scale.y > 1.5
		var color: Color = enemy_color
		var marker_size: float = enemy_size

		if is_elite:
			color = elite_color
			marker_size = elite_size
		elif enemy.is_in_group("guard_enemies"):
			color = guard_color

		_draw_arrow(marker_position, center, marker_size, color)

		if is_elite:
			draw_arc(marker_position, marker_size + 4.0, 0.0, TAU, 20, elite_color, 1.5)


func _draw_powerups(player: Node3D, center: Vector2, radius: float) -> void:
	for powerup: Node in get_tree().get_nodes_in_group("powerups"):
		if not powerup is Node3D:
			continue
		var marker_position: Vector2 = _to_radar((powerup as Node3D).global_position, player, center, radius)
		draw_circle(marker_position, 4.0, powerup_color)


func _draw_events(player: Node3D, center: Vector2, radius: float) -> void:
	# Rombo del color del evento: ayuda a priorizar el objetivo en la arena.
	for node: Node in get_tree().get_nodes_in_group("arena_events"):
		if not node is Node3D:
			continue
		var marker_position: Vector2 = _to_radar(
			(node as Node3D).global_position, player, center, radius
		)
		var color: Color = event_color
		if node.has_method("get_accent"):
			color = node.call("get_accent")
		var half: float = 5.0
		var points := PackedVector2Array([
			marker_position + Vector2(0.0, -half),
			marker_position + Vector2(half, 0.0),
			marker_position + Vector2(0.0, half),
			marker_position + Vector2(-half, 0.0),
		])
		draw_colored_polygon(points, color)
		draw_arc(marker_position, half + 2.0, 0.0, TAU, 16, color, 1.0)


func _draw_player(center: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -8.0),
		center + Vector2(-5.0, 5.0),
		center + Vector2(5.0, 5.0),
	])
	draw_colored_polygon(points, player_color)


func _draw_arrow(position: Vector2, center: Vector2, marker_size: float, color: Color) -> void:
	var direction: Vector2 = center - position
	if direction.length() < 0.1:
		direction = Vector2.UP
	else:
		direction = direction.normalized()

	var side: Vector2 = Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		position + direction * marker_size,
		position - direction * marker_size * 0.7 + side * marker_size * 0.7,
		position - direction * marker_size * 0.7 - side * marker_size * 0.7,
	])
	draw_colored_polygon(points, color)


func _to_radar(world_position: Vector3, player: Node3D, center: Vector2, radius: float) -> Vector2:
	# Relativo al jugador, rotado para que su frente quede arriba.
	var relative: Vector2 = Vector2(
		world_position.x - player.global_position.x,
		world_position.z - player.global_position.z
	)
	relative = relative.rotated(player.global_rotation.y)

	var distance: float = relative.length()
	if distance > radar_range:
		relative = relative / distance * radar_range

	return center + relative * (radius / radar_range)
