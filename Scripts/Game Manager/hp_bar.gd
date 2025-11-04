# Script controlling the hp bar

extends ProgressBar

# How fast it floats
@export var float_speed := 1.5

# How high it floats to
@export var float_height := 1.0

# Amplitude of the float (in radians)
@export var tilt_amplitude := 0.02 

var base_y := 0.0
var time := 0.0

# Setup the hp bar
func _ready() -> void:
	base_y = position.y

	# Offset the center to 25% from the left (horizontal), 50% vertical
	pivot_offset = Vector2(size.x * -0.0001, size.y * 0.5)

# Have it floating above
func _process(delta: float) -> void:
	time += delta

	# Floating
	position.y = base_y + sin(time * float_speed) * float_height

	# Tilting
	rotation = sin(time * float_speed) * tilt_amplitude
