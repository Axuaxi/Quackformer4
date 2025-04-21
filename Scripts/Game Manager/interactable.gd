extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Quack":
		print("🎯 Interactable hit!")
		
		hide()
		
		var portal_in = get_parent().get_node("PortalEntrance")
		var portal_out = get_parent().get_node("PortalExit")
		
		portal_in.visible = true
		portal_in.monitoring = true
		portal_out.visible = true
		
		var label1 = get_node_or_null("../Label")
		var label2 = get_node_or_null("../Label2")
		
		label1.visible = false
		label2.visible = true
