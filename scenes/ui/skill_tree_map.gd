extends Control

const MAP_SIZE: Vector2 = Vector2(1000.0, 360.0)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.055, 0.08, 0.12, 1.0), true)

	for x in range(100, int(MAP_SIZE.x), 100):
		draw_line(Vector2(x, 0.0), Vector2(x, MAP_SIZE.y), Color(1, 1, 1, 0.035), 1.0)
	for y in range(100, int(MAP_SIZE.y), 100):
		draw_line(Vector2(0.0, y), Vector2(MAP_SIZE.x, y), Color(1, 1, 1, 0.035), 1.0)

	for id in SkillTree.NODES:
		var data: Dictionary = SkillTree.get_node_data(str(id))
		var to_position: Vector2 = _node_center(str(id))
		var color: Color = _node_color(str(id), true)
		for required in data.get("requires", []):
			draw_line(_node_center(str(required)), to_position, color, 3.0)

	for id in SkillTree.NODES:
		draw_circle(_node_center(str(id)), 4.0, _node_color(str(id), false))


func _node_center(skill_id: String) -> Vector2:
	var data: Dictionary = SkillTree.get_node_data(skill_id)
	var position: Vector2 = data.get("position", Vector2(0.5, 0.5))
	return position * MAP_SIZE


func _node_color(skill_id: String, is_line: bool) -> Color:
	if GameState.get_skill_level(skill_id) > 0:
		return Color(0.95, 0.75, 0.25, 0.9)
	if GameState.is_skill_available(skill_id):
		return Color(0.3, 0.85, 0.8, 0.8 if is_line else 0.95)
	return Color(0.3, 0.36, 0.45, 0.45)
