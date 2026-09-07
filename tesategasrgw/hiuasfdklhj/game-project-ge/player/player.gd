extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

var voice_input := Vector2.ZERO
@onready var speech_status: Label = $SpeechStatusLayer/SpeechStatus
@onready var speech_text: Label = $SpeechStatusLayer/SpeechText
@onready var speech_command: Label = $SpeechStatusLayer/SpeechCommand

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SpeechManager.speech_result.connect(_on_speech)
	SpeechManager.speech_error.connect(_on_speech_error)
	SpeechManager.listening_started.connect(_on_listening_started)
	SpeechManager.listening_stopped.connect(_on_listening_stopped)
	if not OS.has_feature("web"):
		speech_status.text = "Speech input: export to Web to enable"
		speech_command.text = "Command: waiting for speech"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the whole player body left/right (yaw)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var voice_pressed := event.is_action_pressed("voice_listen")
	var voice_released := event.is_action_released("voice_listen")
	if event is InputEventKey and event.physical_keycode == KEY_V:
		voice_pressed = voice_pressed or event.pressed
		voice_released = voice_released or not event.pressed

	if voice_pressed:
		speech_status.text = "V pressed - requesting microphone..."
		SpeechManager.start_listening()
	if voice_released:
		speech_status.text = "V released - stopping listening..."
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
	speech_text.text = "Decoded text: " + text
	match command:
		"forward", "move forward", "go forward":
			voice_input = Vector2.UP
			speech_command.text = "Command: moving forward"
		"back", "backward", "move backward", "go backward":
			voice_input = Vector2.DOWN
			speech_command.text = "Command: moving backward"
		"left", "move left", "go left":
			voice_input = Vector2.LEFT
			speech_command.text = "Command: moving left"
		"right", "move right", "go right":
			voice_input = Vector2.RIGHT
			speech_command.text = "Command: moving right"
		"stop", "stop moving", "halt":
			voice_input = Vector2.ZERO
			speech_command.text = "Command: stopped"
		_:
			speech_command.text = "Command: not recognized"

func _on_speech_error(error: String) -> void:
	speech_status.text = "Speech error: " + error
	speech_command.text = "Command: unavailable"

func _on_listening_started() -> void:
	speech_status.text = "Listening..."

func _on_listening_stopped() -> void:
	speech_status.text = "Hold V to speak"
