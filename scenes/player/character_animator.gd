extends Sprite2D
class_name CharacterAnimator

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var animation_tree : AnimationTree= $AnimationTree

var impact : float = 0
var prev_direction := 0
var do_next_jump_tween := false
var straight_jump := false
var jump_tween : Tween = null
var character_controller

func set_controller(controller):
	character_controller = controller

func set_anim_param(parameter: String, value: int) -> void:
	animation_tree.set("parameters/%s/current" % parameter, value)

func activate_anim_param(parameter: String) -> void:
	animation_tree.set("parameters/%s/active" % parameter, true)

func walk_tween(direction: int) -> Tween:
	if prev_direction == direction: return
	prev_direction = direction
	var tween = create_tween()
	tween.tween_property(self, "rotation", 0.15 * direction, 0.05)
	
	return tween

func jump_squash_tween(target: Vector2):
	if do_next_jump_tween:
		jump_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC);
		jump_tween.tween_property(self, "scale", target, 0.075)
	else:
		scale = target

func land():
	do_next_jump_tween = false
	straight_jump = false
	if jump_tween != null:
		jump_tween.kill()
		jump_tween = null

func animate(direction: int, on_floor: bool, velocity: Vector2) -> void:
	set_anim_param("is_moving", direction != 0)
	set_anim_param("in_air", not on_floor)
	if Input.is_action_just_pressed("jump") and character_controller.falling < 8: activate_anim_param("jumped")
	
	if direction != 0: flip_h = direction < 0
	
	if on_floor:
		if impact > 0:
			var squash_factor: float = min(impact / 10.0, 50.0) / 80.0
			scale = Vector2(
				1 + squash_factor,
				1 - squash_factor
			)
			impact -= 50
			
		else: 
			scale = Vector2(1, 1)
			
			if impact < 0 or impact > 0: impact = 0
		
		walk_tween(direction)
	else:
		
		var squash_factor : float = min((min(velocity.y, character_controller.gravity * 10) * 0.5) / (character_controller.JUMP_VELOCITY * (2 if velocity.y > 0 else 1)), 0.3)
		jump_squash_tween(Vector2(
			1 - squash_factor,
			1 + squash_factor
		))
		impact = velocity.y * 1.5;
		
		if !straight_jump: walk_tween(1 if flip_h else -1)
		else: walk_tween(0)
