extends Area2D

signal player_touched

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_touched.emit()
