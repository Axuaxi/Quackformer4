# Global dialogue system (WIP)

extends CanvasLayer

signal dialogue_finished

var is_active := false
var lines: Array[String] = []
var current_line := 0
var typing := false

@onready var label: Label = $Panel/Label

# Starts the dialogue line, takes in the dialogue u wanna have said
func start_dialogue(new_lines: Array[String]) -> void:
	# If the dialogue is already happening then do nothing
	if is_active:
		return
	
	# Else start talking
	is_active = true
	lines = new_lines
	current_line = 0
	show()
	_show_line()

# Shows the current line in the dialogue array
func _show_line() -> void:
	typing = true
	label.text = ""
	var line = lines[current_line]

	# Little animation for the dialogue so its not so static
	for i in line.length():
		label.text += line[i]
		await get_tree().create_timer(0.03).timeout
		# Skips current line and goe sto next line (TODO: fix cus its lowkey kinda buggy)
		if Input.is_action_pressed("skip dialogue"):
			label.text = line
			break

	# resets the typing for the animation
	typing = false

# Unhandled input here
func _unhandled_input(event: InputEvent) -> void:
	if typing or not is_active:
		return

	if event.is_action_pressed("skip dialogue"):
		current_line += 1
		if current_line >= lines.size():
			hide()
			is_active = false
			emit_signal("dialogue_finished")
		else:
			_show_line()
