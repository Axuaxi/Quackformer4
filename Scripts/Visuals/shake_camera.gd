# Script to shake the camera

extends Camera2D

var shake_strength := 0.0

# Processes the shake
func _process(delta):
	if shake_strength > 0:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_strength
		shake_strength = lerp(shake_strength, 0.0, delta * 5)
	else:
		offset = Vector2.ZERO

# Sets the strength of the shake
func shake(amount: float) -> void:
	shake_strength = amount
