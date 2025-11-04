# Script controlling the player interacting with the portal entrance

extends Area2D

func _on_body_entered(body: Node) -> void:
	# Cus player node main node is called that
	if body.name == "Player":
		var portal_out = get_parent().get_node("PortalExit")
		body.global_position = portal_out.global_position
		var label2 = get_node_or_null("../Label2")
		var portal_entrance = get_parent().get_node("PortalEntrance")
		
		# Nice little fadeout animation for the label
		if label2:
			var tween := create_tween()
			# fade to invisible in 0.5s
			tween.tween_property(label2, "modulate:a", 0.0, 0.5)  
			
