extends Control

@export_group("Crosshair")
@export var gap: float = 4.0
@export var line_length: float = 8.0
@export var line_width: float = 2.0
@export var dot_radius: float = 1.5
@export var color: Color = Color(0, 0, 0, 1)
@export var outline_color: Color = Color(1, 1, 1, 0.85)
@export var outline_extra_width: float = 2.0

@export_group("Hitmarker")
@export var hitmarker_gap: float = 9.0
@export var hitmarker_length: float = 9.0
@export var hitmarker_width: float = 2.5
@export var hitmarker_duration: float = 0.22
@export var headshot_color: Color = Color(1.0, 0.84, 0.3, 1.0)
@export var torso_color: Color = Color(0.95, 0.97, 1.0, 1.0)
@export var legs_color: Color = Color(0.3, 0.85, 1.0, 1.0)

var _hit_timer: float = 0.0
var _hit_color: Color = Color.WHITE
var _hit_punch: float = 0.0


func _ready() -> void:
	EventBus.enemy_hit.connect(_on_enemy_hit)


func _process(delta: float) -> void:
	if _hit_timer <= 0.0:
		return
	_hit_timer = maxf(_hit_timer - delta, 0.0)
	_hit_punch = maxf(_hit_punch - delta * 4.0, 0.0)
	queue_redraw()


func _on_enemy_hit(
	_enemy: Node, hit_zone: String, _damage: float, _money: int
) -> void:
	match hit_zone:
		"head":
			_hit_color = headshot_color
			_hit_punch = 1.0
		"legs":
			_hit_color = legs_color
			_hit_punch = 0.25
		_:
			_hit_color = torso_color
			_hit_punch = 0.0
	_hit_timer = hitmarker_duration
	queue_redraw()


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

	if _hit_timer <= 0.0:
		return

	var alpha: float = clampf(_hit_timer / maxf(hitmarker_duration, 0.01), 0.0, 1.0)
	var mark_color: Color = _hit_color
	mark_color.a = alpha
	var mark_outline := Color(0.0, 0.0, 0.0, alpha * 0.6)
	var expansion: float = (1.0 - alpha) * 4.0 + _hit_punch * 2.0
	var diagonals: Array[Vector2] = [
		Vector2(1, 1),
		Vector2(1, -1),
		Vector2(-1, 1),
		Vector2(-1, -1),
	]

	for diagonal: Vector2 in diagonals:
		var direction: Vector2 = diagonal.normalized()
		var start: Vector2 = center + direction * (hitmarker_gap + expansion)
		var end: Vector2 = center + direction * (hitmarker_gap + hitmarker_length + expansion)
		draw_line(start, end, mark_outline, hitmarker_width + 2.0, true)
		draw_line(start, end, mark_color, hitmarker_width, true)
