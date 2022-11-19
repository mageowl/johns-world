extends Sprite2D

var prev_position := Vector2.ZERO 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var target = clamp((position.x - prev_position.x) * 0.5, -1, 1)
	position = get_global_mouse_position()
	rotation = lerp(rotation, float(clamp((position.x - prev_position.x) * 0.8, -0.6, 0.6)), 0.4)
	prev_position = position
