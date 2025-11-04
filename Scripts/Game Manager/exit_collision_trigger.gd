# Script controlling whether the exit trigger is on or not

extends CollisionShape2D

# Disables the visibility and disabled of the collision
func _ready() -> void:
	visible = false
	disabled = true
