# Script to regulate the autoscrolling camera once it hits the desired y level

extends Area2D

@export var lava: Node
@export var camera: Node

# Starts the autoscroll if the player entered the autoscroll zone
func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		if lava:
			lava.call("start_rising")
		if camera:
			camera.set("scrolling", true)
		queue_free()
