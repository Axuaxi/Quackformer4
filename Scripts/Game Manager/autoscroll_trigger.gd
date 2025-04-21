extends Area2D

@export var lava: Node
@export var camera: Node

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		print("🚀 Scroll triggered!")
		if lava:
			lava.call("start_rising")  # instead of lava.set("scrolling", true)
		if camera:
			camera.set("scrolling", true)
		queue_free()
