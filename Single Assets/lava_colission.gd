# Lava collision with the player script

extends RigidBody2D

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.queue_free()  
