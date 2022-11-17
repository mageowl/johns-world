extends CharacterBody2D
class_name CharacterController

enum tree_param {
	YES,
	NO
}

const SPEED = 150.0
const JUMP_VELOCITY = 350.0
const MIN_JUMP_VELOCITY = 100.0

const CAM_CORRECTION = Vector2(0, 0)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite : CharacterAnimator = $Sprite
@onready var camera : Camera2D = $Camera2d
var falling = 0
var has_borders = false

func _ready():
	sprite.set_controller(self)

func movement(delta):
	var direction = Input.get_axis("walk_left", "walk_right")
	
	if not is_on_floor():
		velocity.y += gravity * delta
		falling += 1
	else: 
		falling = 0
		sprite.land();
	
	if Input.is_action_just_pressed("jump") and falling < 8:
		velocity.y = -JUMP_VELOCITY
		sprite.straight_jump = direction == 0
	
	if Input.is_action_just_released("jump") and velocity.y < -MIN_JUMP_VELOCITY:
		velocity.y = -MIN_JUMP_VELOCITY
		sprite.do_next_jump_tween = true
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	return direction
func is_in_bounds(num: float):
	return num > 0 and num < 1

func camera_check():
	var cam_pos: Vector2 = get_global_transform_with_canvas().origin / get_viewport_rect().size
	
	if not (is_in_bounds(cam_pos.x) and is_in_bounds(cam_pos.y)) or not has_borders:
		var borders = Global.camera_borders.get_border(position)
		if borders != Global.camera_borders.NO_BORDER: 
			has_borders = true
			
			camera.set_limit(SIDE_LEFT, borders.position.x + CAM_CORRECTION.x)
			camera.set_limit(SIDE_TOP, borders.position.y + CAM_CORRECTION.y)
			camera.set_limit(SIDE_RIGHT, borders.end.x + CAM_CORRECTION.x)
			camera.set_limit(SIDE_BOTTOM, borders.end.y + CAM_CORRECTION.y)

func _physics_process(delta):
	var direction = movement(delta)
	sprite.animate(direction, is_on_floor(), velocity)
	camera_check()

	move_and_slide()
