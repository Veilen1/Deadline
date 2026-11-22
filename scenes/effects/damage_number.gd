extends Label3D

## Número de daño flotante. Sube y se desvanece.

@export var lifetime: float = 0.7
@export var rise_distance: float = 1.2
@export var normal_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var strong_color: Color = Color(1.0, 0.55, 0.15, 1.0)
@export var strong_threshold: float = 40.0
@export var random_spread: float = 0.25
@export var heal_color: Color = Color(0.35, 1.0, 0.55, 1.0)


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	font_size = 64
	outline_size = 12
	pixel_size = 0.006


func show_damage(world_position: Vector3, amount: float) -> void:
	text = str(int(round(amount)))
	modulate = strong_color if amount >= strong_threshold else normal_color
	_animate(world_position)


func show_heal(world_position: Vector3, amount: float) -> void:
	# Curación de enemigos por el evento "Núcleo sanitario".
	text = "+%d" % int(round(amount))
	modulate = heal_color
	_animate(world_position)


func _animate(world_position: Vector3) -> void:
	global_position = world_position + Vector3(
		randf_range(-random_spread, random_spread),
		0.0,
		randf_range(-random_spread, random_spread)
	)

	scale = Vector3.ONE * 0.6

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ONE, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", global_position + Vector3.UP * rise_distance, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "outline_modulate:a", 0.0, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
