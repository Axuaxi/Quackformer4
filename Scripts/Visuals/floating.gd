# Script controlling the floating text

extends Sprite2D

# How fast it floats
@export var float_speed := 1.5
# How high it floats
@export var float_height := 1.0
# The tilt in radians
@export var tilt_amplitude := -0.02
var base_y := 0.0
var base_rotation := 0.0
var time := 0.0

func _ready() -> void:
	base_y = global_position.y
	# Store the initial rotation
	base_rotation = rotation  

func _process(delta: float) -> void:
	time += delta

	# Floating
	global_position.y = base_y + sin(time * float_speed) * float_height

	# Tilting relative to original rotation
	rotation = base_rotation + sin(time * float_speed) * tilt_amplitude
