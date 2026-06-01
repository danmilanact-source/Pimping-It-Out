extends CharacterBody3D
signal looking(object_name)
signal hud_visible(is_visible: bool)
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
var sprint_SPEED = 15.0
var crouch_SPEED = 2.0
const JUMP_VELOCITY = 6.5
const lerp_SPEED = 5.0
const crouch_POS = -1
const crouching_height = 1.5
const standing_height = 2.5
var mouse_SENS = 0.2
var direction = Vector3.ZERO

#Testing
var label: Label
var mouse_RELEASED = false
# Player
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var collision_SHAPE = $CollisionShape
@onready var crouch_SHAPE = $CrouchDetection

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	label = Label.new()
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.position.y -= 50
	
func _input(event) -> void:
	if event is InputEventMouseMotion:
		if mouse_RELEASED: #Locks the camera in place
			return
		rotate_y(-deg_to_rad(event.relative.x * mouse_SENS))
		head.rotate_x(-deg_to_rad(event.relative.y * mouse_SENS))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90),deg_to_rad(88))

	if Input.is_action_just_pressed("MouseRelease"):
		mouse_RELEASED = !mouse_RELEASED
		label.visible = !label.visible
		if mouse_RELEASED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			hud_visible.emit(false)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			Input.warp_mouse(get_viewport().get_visible_rect().size / 2) # Gets the mouse back to the center of the screen
			hud_visible.emit(true)

func _physics_process(delta: float) -> void:
	var capsule = collision_SHAPE.shape as CapsuleShape3D
	
	#Cursor Collision Check
	if looking_at() != null:
		label.text = looking_at()
		looking.emit(looking_at())
	else:
		label.text = "Air"
		looking.emit(null)
	
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
		elif not crouch_SHAPE.is_colliding():
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

func looking_at():
	var ray_LENGTH = 8
	var origin = camera.global_position
	var direction = -camera.global_transform.basis.z
	var destination = origin + direction * ray_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, destination)
	var space_STATE = get_world_3d().direct_space_state
	var result = space_STATE.intersect_ray(query)
	if result:
		return result.collider.name
	else:
		return null
	
