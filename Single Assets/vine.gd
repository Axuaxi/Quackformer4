extends TileMapLayer

@export var float_speed := 1.5
@export var float_height := 1.0
@export var tilt_amplitude := -0.02  # in radians

var base_position := Vector2.ZERO
var base_rotation := 0.0
var pivot := Vector2.ZERO
var time := 0.0

func _ready() -> void:
	base_position = global_position
	base_rotation = rotation

	# Get the used rectangle in local coords and center of it in pixels
	var rect = get_used_rect()
	pivot = map_to_local(rect.position + rect.size / 2)

func _process(delta: float) -> void:
	time += delta

	var float_offset := sin(time * float_speed) * float_height
	var tilt := sin(time * float_speed) * tilt_amplitude

	# Reset before applying new transform
	global_position = base_position
	rotation = base_rotation

	# Apply rotation around the pivot (center)
	var transform = Transform2D()
	transform.origin = pivot.rotated(tilt) - pivot
	transform = transform.rotated(tilt)

	# Apply final transform
	set_global_transform(Transform2D(tilt, base_position + Vector2(0, float_offset) + transform.origin))
