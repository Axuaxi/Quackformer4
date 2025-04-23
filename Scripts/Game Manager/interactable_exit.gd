extends Area2D

signal level_completed
var interactive_done := false

func _ready():
	interactive_done = false

func _on_body_entered(body: Node) -> void:
	if interactive_done:
		if body.name == "Player":
			print("🚪 Exit triggered!")
			level_completed.emit()
