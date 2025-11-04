# Script controlling the floating text in certain levels

extends Label

# How fast the text floats
@export var float_speed := 1.5

# How far the text floats
@export var float_height := 1.0

# How much the text floats (in radians)
@export var tilt_amplitude := 0.02 

var base_y := 0.0
var time := 0.0

func _ready() -> void:
	base_y = global_position.y

	# Offset the center to 25% from the left (horizontal), 50% vertical
	pivot_offset = Vector2(size.x * -0.0001, size.y * 0.5)

func _process(delta: float) -> void:
	time += delta

	# Floating
	global_position.y = base_y + sin(time * float_speed) * float_height

	# Tilting
	rotation = sin(time * float_speed) * tilt_amplitude
