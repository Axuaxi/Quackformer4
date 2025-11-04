# Script controlling the exit of an interactable level

extends Area2D

signal level_completed
var interactive_done := false

# Sets the interactable to false so you cant cheese it
func _ready():
	interactive_done = false

# Only show up and is exitable once the player finishes the interactable
func _on_body_entered(body: Node) -> void:
	if interactive_done:
		if body.name == "Player":
			level_completed.emit()
