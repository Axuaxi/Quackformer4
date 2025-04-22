extends Button

#@export var float_speed := 1.5
#@export var float_height := 1.0
#@export var tilt_amplitude := 0.02  # in radians
#
#var base_y := 0.0
#var time := 0.0
#
#func _ready() -> void:
	#base_y = global_position.y
	#var panel = get_parent().get_node("BonusPanel")
	#
	## Offset the center to 25% from the left (horizontal), 50% vertical
	#pivot_offset = Vector2(-size.x, size.y * 0.5)
#
#func _process(delta: float) -> void:
	#time += delta
#
	## Floating
	#global_position.y = base_y + sin(time * float_speed) * float_height
#
	## Tilting
	#rotation = sin(time * float_speed) * tilt_amplitude

func _on_pressed() -> void:
	var panel = get_parent().get_node("DifficultyPanel")
	if panel:
		panel.visible = true
