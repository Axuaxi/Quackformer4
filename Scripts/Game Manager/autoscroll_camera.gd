extends Camera2D

@export var scroll_speed := 40
@export var stop_y := -1000  # Change this to the Y value you want to stop at
var scrolling := false

func _process(delta: float) -> void:
	if scrolling:
		if global_position.y <= stop_y:
			print("🛑 Camera stopped at", stop_y)
			scrolling = false
			return

		global_position.y -= scroll_speed * delta
