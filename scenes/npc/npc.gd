extends Area2D

@export var dialog_resource : Resource
@export var current_title : String = "introduction"
@onready var animation_player = $PopUp/AnimationPlayer

func _on_mouse_entered():
	animation_player.play("Appear")


func _on_mouse_exited():
	animation_player.play("Disappear")


func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_action("left_mouse"):
		Global.start_dialog(dialog_resource)
