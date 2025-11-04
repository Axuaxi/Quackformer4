# Script controlling the exit trigger

extends Area2D

signal level_completed

# Allows the player to exit the level
func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		# This transitions the player to the next level ostts
		level_completed.emit()
