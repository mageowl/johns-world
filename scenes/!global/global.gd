extends Node

var camera_borders : CameraBorders

func save(node: Node):
	var varible_name = str(node.name).to_snake_case()
	self[varible_name] = node
