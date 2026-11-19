extends CharacterBody3D

@export_group("Movement")
@export var move_speed: float = 5.0
@export var gravity: float = 20.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var camera_height: float = 1.5
@export var camera_pitch_limit_deg: float = 80.0

@onready var camera: Camera3D = $Camera3D
@onready var shoot_origin: Marker3D = $Camera3D/ShootOrigin


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.position.y = camera_height
	# TODO: Fase 1.3 — viewmodel/brazos en primera persona (el mesh del cuerpo está oculto).


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		# Yaw sobre el cuerpo; pitch sobre la cámara (primera persona).
		rotate_y(-event.relative.x * mouse_sensitivity)
		var pitch_limit: float = deg_to_rad(camera_pitch_limit_deg)
		camera.rotation.x = clampf(
			camera.rotation.x - event.relative.y * mouse_sensitivity,
			-pitch_limit,
			pitch_limit
		)

	# TODO: Fase 1.3 — conectar el input "shoot" con shoot().


func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)

	var body_basis: Basis = global_basis
	var direction: Vector3 = body_basis.x * input_vector.x + body_basis.z * input_vector.y
	direction.y = 0.0
	if direction.length_squared() > 0.0:
		direction = direction.normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func shoot() -> void:
	# TODO: Fase 1.3 — raycast desde la cámara, detección de hit_zone y llamada a take_hit().
	pass
