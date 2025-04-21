extends Area2D

signal level_completed

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		print("🚪 Exit triggered!")
		level_completed.emit()
