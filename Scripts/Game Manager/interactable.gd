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
		
		if label1:
			var tween := create_tween()
			tween.tween_property(label1, "modulate:a", 0.0, 0.5)  # fade to invisible in 0.5s

		label2.visible = true
