extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

var voice_input := Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SpeechManager.speech_result.connect(_on_speech)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the whole player body left/right (yaw)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("voice_listen"):
		SpeechManager.start_listening()
	if event.is_action_released("voice_listen"):
		SpeechManager.stop_listening()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if voice_input != Vector2.ZERO:
		input_dir = voice_input
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _on_speech(text: String) -> void:
	var command := text.to_lower().strip_edges().replace(".", "")
	match command:
		"forward", "move forward", "go forward":
			voice_input = Vector2.UP
		"back", "backward", "move backward", "go backward":
			voice_input = Vector2.DOWN
		"left", "move left", "go left":
			voice_input = Vector2.LEFT
		"right", "move right", "go right":
			voice_input = Vector2.RIGHT
		"stop", "stop moving", "halt":
			voice_input = Vector2.ZERO
