extends Area2D

func _on_body_entered(body: Node) -> void:
	if body.name == "Player": # Cus player node main node is called that
		var portal_out = get_parent().get_node("PortalExit")
		body.global_position = portal_out.global_position
		var label2 = get_node_or_null("../Label2")
		if label2:
			var tween := create_tween()
			tween.tween_property(label2, "modulate:a", 0.0, 0.5)  # fade to invisible in 0.5s
