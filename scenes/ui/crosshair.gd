extends Control

@export_group("Crosshair")
@export var gap: float = 4.0
@export var line_length: float = 8.0
@export var line_width: float = 2.0
@export var dot_radius: float = 1.5
@export var color: Color = Color(0, 0, 0, 1)
@export var outline_color: Color = Color(1, 1, 1, 0.85)
@export var outline_extra_width: float = 2.0


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]

	for direction: Vector2 in directions:
		var start: Vector2 = center + direction * gap
		var end: Vector2 = center + direction * (gap + line_length)
		if outline_extra_width > 0.0:
			draw_line(start, end, outline_color, line_width + outline_extra_width)
		draw_line(start, end, color, line_width)

	if dot_radius > 0.0:
		if outline_extra_width > 0.0:
			draw_circle(center, dot_radius + outline_extra_width * 0.5, outline_color)
		draw_circle(center, dot_radius, color)
