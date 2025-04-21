extends RigidBody2D

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		print("🔥 Lava hit the player!")
		body.queue_free()  # Or emit a signal to restart level
