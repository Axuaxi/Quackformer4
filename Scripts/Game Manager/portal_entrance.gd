extends Area2D

func _on_body_entered(body: Node) -> void:
	if body.name == "Player": # Cus player node main node is called that
		var portal_out = get_parent().get_node("PortalExit")
		body.global_position = portal_out.global_position
