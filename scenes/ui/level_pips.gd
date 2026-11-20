extends Control

## Pequeño gráfico de barras para niveles de un nodo (máx. 5, 3 o 1).

var current_level: int = 0
var max_level: int = 1


func set_levels(current: int, maximum: int) -> void:
	current_level = clampi(current, 0, maximum)
	max_level = maxi(maximum, 1)
	queue_redraw()


func _draw() -> void:
	if max_level <= 0:
		return

	var gap: float = 4.0
	var bar_width: float = (size.x - gap * float(max_level - 1)) / float(max_level)
	var bar_height: float = size.y

	for index in max_level:
		var rect := Rect2(
			Vector2(float(index) * (bar_width + gap), 0.0),
			Vector2(bar_width, bar_height)
		)
		var color := Color(0.95, 0.75, 0.25, 1.0) if index < current_level else Color(0.18, 0.24, 0.33, 1.0)
		draw_rect(rect, color, true)
