extends Node

const DIALOG_BOX := preload("res://scenes/dialog/dialog_box.tscn")

var camera_borders : CameraBorders
var in_dialog := false

func save(node: Node, text: String):
	print(text)
	self[text] = node

func start_dialog(resource: Resource, title: String = "0", game_state: Array = []):
	if in_dialog: return
	in_dialog = true
	get_tree().paused = true
	
	var balloon = DIALOG_BOX.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(resource, title, game_state)
	balloon.end_dialog.connect(_dialog_end)

func _dialog_end():
	in_dialog = false
	get_tree().paused = false
