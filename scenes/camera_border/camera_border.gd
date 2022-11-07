@tool
extends Node2D
class_name CameraBorders

const NO_BORDER := Rect2(0, 0, 0, 0)

var camera_borders : Array[Rect2] = Array()

func _enter_tree():
	Global.save(self, "camera_borders")

func _ready():
	for node in get_children():
		if node is ColorRect:
			var rect = node.get_rect()
			camera_borders.append(rect)
	
	visible = false

func inside(rect: Rect2, point: Vector2) -> bool:
	return rect.position.x <= point.x and rect.position.y <= point.y and rect.end.x >= point.x and rect.end.y >= point.y

func get_border(position: Vector2) -> Rect2:
	var arr = camera_borders.filter(func(border: Rect2): 
		return border.has_point(position)
	)
	return NO_BORDER if arr.size() == 0 else arr[0]
