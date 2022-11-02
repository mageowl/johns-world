extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = 350.0
const MIN_JUMP_VELOCITY = 100.0

const CAM_CORRECTION = Vector2(0, 0)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animation := $Sprite/AnimationPlayer
@onready var sprite : Sprite2D = $Sprite
@onready var camera : Camera2D = $Camera2d
var falling = 0
var has_borders = false

# Dialogs
var dialog = load("res://scenes/world/water-gun.dialogue")

# Animation varibles
var prev_direction = 0
var impact : float = 0
var do_next_jump_tween := false
var straight_jump := false

func movement(delta):
	var direction = Input.get_axis("walk_left", "walk_right")
	
	if not is_on_floor():
		velocity.y += gravity * delta
		falling += 1
	else: 
		falling = 0
		do_next_jump_tween = false
		straight_jump = false
	
	if Input.is_action_just_pressed("jump") and falling < 8:
		velocity.y = -JUMP_VELOCITY
		straight_jump = direction == 0
	
	if Input.is_action_just_released("jump") and velocity.y < -MIN_JUMP_VELOCITY:
		velocity.y = -MIN_JUMP_VELOCITY
		do_next_jump_tween = true
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	return direction

func walk_tween(direction: int) -> Tween:
	if prev_direction == direction: return
	prev_direction = direction
	var tween = create_tween()
	tween.tween_property(sprite, "rotation", 0.15 * direction, 0.05)
	
	return tween

func jump_squash_tween(target: Vector2):
	if do_next_jump_tween:
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC);
		tween.tween_property(sprite, "scale", target, 0.075)
	else:
		sprite.scale = target

func animate(direction: int):
	if direction != 0: sprite.flip_h = direction < 0
	
	if is_on_floor():
		
		if impact > 0:
			var squash_factor: float = min(impact / 10.0, 50.0) / 80.0
			sprite.scale = Vector2(
				1 + squash_factor,
				1 - squash_factor
			)
			impact -= 50
			
		else: 
			sprite.scale = Vector2(1, 1)
			
			if impact < 0 or impact > 0: impact = 0
		
		if direction != 0:
			animation.play("Walk")
		else: animation.play("Idle")
		
		walk_tween(direction)
	else:
		
		animation.play("Air")
		
		var squash_factor : float = min((min(velocity.y, gravity * 10) * 0.5) / (JUMP_VELOCITY * (2 if velocity.y > 0 else 1)), 0.3)
		jump_squash_tween(Vector2(
			1 - squash_factor,
			1 + squash_factor
		))
		impact = velocity.y * 1.5;
		
		if !straight_jump: walk_tween(1 if sprite.flip_h else -1)
		else: walk_tween(0)

func is_in_bounds(num: float):
	return num > 0 and num < 1

func camera_check():
	var cam_pos: Vector2 = get_global_transform_with_canvas().origin / get_viewport_rect().size
	
	if not (is_in_bounds(cam_pos.x) and is_in_bounds(cam_pos.y)) or not has_borders:
		var borders = GlobalNode.camera_borders.get_border(position)
		if borders != GlobalNode.camera_borders.NO_BORDER: 
			has_borders = true
			
			camera.set_limit(SIDE_LEFT, borders.position.x + CAM_CORRECTION.x)
			camera.set_limit(SIDE_TOP, borders.position.y + CAM_CORRECTION.y)
			camera.set_limit(SIDE_RIGHT, borders.end.x + CAM_CORRECTION.x)
			camera.set_limit(SIDE_BOTTOM, borders.end.y + CAM_CORRECTION.y)

func _physics_process(delta):
	var direction = movement(delta)
	animate(direction)
	camera_check()
	
	if Input.is_key_pressed(KEY_F):
		DialogueManager.show_example_dialogue_balloon(dialog, "this_is_a_node_title")

	move_and_slide()
