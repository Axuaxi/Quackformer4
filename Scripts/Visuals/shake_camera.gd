# CameraShake.gd (attached to Camera2D)
extends Camera2D

var shake_strength := 0.0

func _process(delta):
	if shake_strength > 0:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_strength
		shake_strength = lerp(shake_strength, 0.0, delta * 5)
	else:
		offset = Vector2.ZERO

func shake(amount: float) -> void:
	shake_strength = amount
