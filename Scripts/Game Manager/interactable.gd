# Script controlling the interactable portal (where you shoot a quack at it and it does something)

extends Area2D

# If a quack enters its hitbox then creates the portals
func _on_area_entered(area: Area2D) -> void:
	if area.name == "Quack":
		
		# Hides the interactable 
		hide()
		
		# Creates the 2 portals
		var portal_in = get_parent().get_node("PortalEntrance")
		var portal_out = get_parent().get_node("PortalExit")
		
		portal_in.visible = true
		portal_in.monitoring = true
		portal_out.visible = true
		
		var label1 = get_node_or_null("../Label")
		var label2 = get_node_or_null("../Label2")
		
		if label1:
			var tween := create_tween()
			# fade to invisible in 0.5s
			tween.tween_property(label1, "modulate:a", 0.0, 0.5)  

		label2.visible = true
