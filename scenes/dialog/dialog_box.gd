extends CanvasLayer
class_name DialogLayer

signal end_dialog

@export var response_template: Node

@onready var balloon: Panel = $Balloon
@onready var margin: MarginContainer = $Balloon/Margin
@onready var character_label: Label = $Balloon/Nameplate/Name
@onready var nameplate: Panel = $Balloon/Nameplate
@onready var dialog_label := $Balloon/Margin/VBox/DialogueLabel
@onready var responses_menu := $Balloon/Margin/VBox/Responses
@onready var localizer := $Balloon/Localizer

var resource: Resource
var temporary_game_states: Array = []
var is_waiting_for_input: bool = false

var dialog_line : Dictionary:
	set(next):
		is_waiting_for_input = false
		
		# If no dialog, hide.
		if next.size() == 0:
			emit_signal("end_dialog")
			tween_close()
			return
		
		# Remove previous responses
		for child in responses_menu.get_children():
			child.free()
		
		# Set line
		dialog_line = next
		
		# Character name
		nameplate.visible = not dialog_line.character.is_empty()
		character_label.text = dialog_line.character.to_lower()
		nameplate.size.x = character_label.get_theme_default_font().get_string_size(character_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 16
		
		# Dialog label size
		dialog_label.modulate.a = 0
		dialog_label.size.x = dialog_label.get_parent().size.x - 1
		dialog_label.dialogue_line = lowercase(dialog_line)
		await dialog_label.reset_height()
		
		# Add responses
		responses_menu.modulate.a = 0
		if dialog_line.responses.size() > 0:
			for response in dialog_line.responses:
				# Duplicate the template so we can grab the fonts, sizing, etc
				var item: RichTextLabel = response_template.duplicate(0)
				item.name = "Response%d" % responses_menu.get_child_count()
				if not response.is_allowed:
					item.name = String(item.name) + "Disabled"
					item.modulate.a = 0.4
				item.text = response.text
				item.show()
				responses_menu.add_child(item)
		
		# Show balloon
		balloon.visible = true
		margin.size = Vector2.ZERO
		
		dialog_label.modulate.a = 1
		if not dialog_line.text.is_empty():
			dialog_label.type_out()
			await dialog_label.finished_typing
		
		if dialog_line.responses.size() > 0:
			responses_menu.modulate.a = 1
			configure_menu()
		elif dialog_line.time != null:
			var time = dialog_line.dialogue.length() * 0.02 if dialog_line.time == "auto" else dialog_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialog_line.next_id)
		else:
			is_waiting_for_input = true
			
			balloon.focus_mode = Control.FOCUS_ALL
			balloon.grab_focus()
	get:
		return dialog_line

# Called when the node enters the scene tree for the first time.
func _ready():
	response_template.hide()
	balloon.hide()
	balloon.custom_minimum_size.x = balloon.get_viewport_rect().size.x
	
	DialogueManager.mutation.connect(_on_mutation)

func start(dialog_resource: Resource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states = extra_game_states
	resource = dialog_resource
	self.dialog_line = await DialogueManager.get_next_dialogue_line(dialog_resource, title, temporary_game_states)

func next(next_id: String) -> void:
	self.dialog_line = await DialogueManager.get_next_dialogue_line(resource, next_id, temporary_game_states)

func lowercase(line: Dictionary) -> Dictionary:
	var new_line = Dictionary(line)
	new_line.text = line.text.to_lower()
	return new_line

func tween_pos(global_pos: Vector2):
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(balloon, "global_position", global_pos, 0.005 * abs(balloon.global_position.y - global_pos.y))

func tween_close():
	var tween = create_tween()
	tween.tween_property(self, "offset:y", balloon.size.y, 0.1)
	tween.tween_callback(queue_free)

func configure_menu() -> void:
	var items = get_responses()
	for i in items.size():
		var item: Control = items[i]
		
		item.focus_mode = Control.FOCUS_ALL
		
		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()
		
		if i == 0:
			item.focus_neighbor_top = item.get_path()
			item.focus_previous = item.get_path()
		else:
			item.focus_neighbor_top = items[i - 1].get_path()
			item.focus_previous = items[i - 1].get_path()
		
		if i == items.size() - 1:
			item.focus_neighbor_bottom = item.get_path()
			item.focus_next = item.get_path()
		else:
			item.focus_neighbor_bottom = items[i + 1].get_path()
			item.focus_next = items[i + 1].get_path()
		
		item.mouse_entered.connect(_on_response_mouse_entered.bind(item))
		item.gui_input.connect(_on_response_gui_input.bind(item))
	
	items[0].grab_focus()

func _on_response_mouse_entered(item: Control) -> void:
	if "Disallowed" in item.name: return
	
	item.grab_focus()


func _on_response_gui_input(event: InputEvent, item: Control) -> void:
	if "Disallowed" in item.name: return
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialog_line.responses[item.get_index()].next_id)
	elif event.is_action_pressed("ui_accept") and item in get_responses():
		next(dialog_line.responses[item.get_index()].next_id)

func _on_balloon_gui_input(event: InputEvent) -> void:
	if not is_waiting_for_input: return

	# When there are no response options the balloon itself is the clickable thing	
	get_viewport().set_input_as_handled()
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialog_line.next_id)
	elif event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == balloon:
		next(dialog_line.next_id)

func get_responses() -> Array:
	var items: Array = []
	for child in responses_menu.get_children():
		if "Disabled" in child.name: continue
		items.append(child)
		
	return items

func _on_mutation() -> void:
	is_waiting_for_input = false
	balloon.hide()

func _on_margin_resized() -> void:
	if not is_instance_valid(margin): return
	# Account for scaling
	balloon.custom_minimum_size.y = margin.size.y * 0.075
	
	var balloon_size_prev = balloon.size.y
	balloon.size.y = 0
	var viewport_size = balloon.get_viewport_rect().size
	tween_pos(Vector2((viewport_size.x - balloon.size.x) * 0.5, viewport_size.y - balloon.size.y))
