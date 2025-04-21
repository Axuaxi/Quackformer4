extends CanvasLayer

signal dialogue_finished

var is_active := false
var lines: Array[String] = []
var current_line := 0
var typing := false

@onready var label: Label = get_node("Panel/Label")

func start_dialogue(new_lines: Array[String]) -> void:
	if is_active:
		print("🛑 Dialogue already playing, skipping new one.")
		return

	is_active = true
	lines = new_lines
	current_line = 0
	show()
	
	_show_line()
	await dialogue_finished  # ✅ Wait until the signal is emitted
	is_active = false

func _show_line() -> void:
	typing = true
	label.text = ""
	var line = lines[current_line]

	for i in line.length():
		label.text += line[i]
		await get_tree().create_timer(0.03).timeout
		if Input.is_action_pressed("skip dialogue"):
			label.text = line
			break

	typing = false

func _unhandled_input(event: InputEvent) -> void:
	if typing or not is_active:
		return

	if event.is_action_pressed("skip dialogue"):
		current_line += 1

		if current_line >= lines.size():
			hide()
			emit_signal("dialogue_finished")  # ✅ Trigger only when all lines are shown
		else:
			_show_line()
