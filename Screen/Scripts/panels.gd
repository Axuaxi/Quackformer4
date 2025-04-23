extends Panel
#
#func _ready() -> void:
	#if visible:
		#PanelManager.push_panel(self)
#
#func _on_visibility_changed() -> void:
	#if visible:
		#PanelManager.push_panel(self)
	#else:
		#PanelManager.panel_stack.erase(self)
#
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and visible:
		print("🔙 Escape: hiding panel:", name)
		visible = false
