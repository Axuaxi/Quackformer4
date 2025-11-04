# Script for the autoscrolling camera during the autoscroll level

extends Camera2D

@export var scroll_speed := 60
@export var stop_y := -1000  # Change this to the Y value you stop at
var scrolling := false

# Processes the scrolling; if the scrolling exceeds the max then stop
func _process(delta: float) -> void:
	if scrolling:
		if global_position.y <= stop_y:
			scrolling = false
			return

		global_position.y -= scroll_speed * delta
