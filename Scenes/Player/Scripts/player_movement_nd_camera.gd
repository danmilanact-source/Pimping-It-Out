extends CharacterBody3D

# States
enum STATE {
	IDLE,
	WALKING,
	SPRINTING,
	CROUCHING
}
var current_STATE = STATE.IDLE

# Speed variables
var current_SPEED = 0.0
var walking_SPEED = 5.0
var sprint_SPEED = 20.0
var crouch_SPEED = 2.0
const JUMP_VELOCITY = 6.5
const lerp_SPEED = 10.0
const crouch_POS = -1
const crouching_height = 1.5
const standing_height = 2.5
var mouse_SENS = 0.2
var direction = Vector3.ZERO

# Player
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var collision_SHAPE = $CollisionShape


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-deg_to_rad(event.relative.x * mouse_SENS))
		head.rotate_x(-deg_to_rad(event.relative.y * mouse_SENS))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90),deg_to_rad(88))

func _physics_process(delta: float) -> void:
	var capsule = collision_SHAPE.shape as CapsuleShape3D
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta * lerp_SPEED)

	# States managing
	if is_on_floor():
		if Input.is_action_pressed("Crouch"):
			current_STATE = STATE.CROUCHING
			current_SPEED = crouch_SPEED
			head.position.y = lerp(head.position.y, 2.5 + crouch_POS , delta * lerp_SPEED)
			capsule.height = lerp(capsule.height, crouching_height, delta * lerp_SPEED)
		else:
			head.position.y = lerp(head.position.y, 2.5, delta * lerp_SPEED)
			capsule.height = lerp(capsule.height, standing_height, delta * lerp_SPEED)
			if Input.is_action_pressed("Sprint") and direction != Vector3.ZERO: #Si te mueves
				current_STATE = STATE.SPRINTING
				current_SPEED = sprint_SPEED
			elif direction != Vector3.ZERO:
				current_STATE = STATE.WALKING
				current_SPEED = walking_SPEED
			else:
				current_STATE = STATE.IDLE
				current_SPEED = walking_SPEED 
			
	if direction:
		velocity.x = direction.x * current_SPEED
		velocity.z = direction.z * current_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, current_SPEED)
		velocity.z = move_toward(velocity.z, 0, current_SPEED)

	move_and_slide()
