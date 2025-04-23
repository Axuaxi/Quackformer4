#extends Panel
#
#var static_escape_handled := false
#
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("pause") and visible:
		#if static_escape_handled:
			#return  # ✅ Someone else already handled it this frame
#
		#var top := _get_topmost_visible_panel()
		#print("Panel:", name, " | topmost =", top?.name if top else "None", " | visible =", visible)
#
		#if self == top:
			#print("🔙 Escape: closing panel:", name)
			#visible = false
			#static_escape_handled = true  # 🛑 stop others this frame
#
## Called by your main scene to reset this before new input each frame
#static func reset_escape_flag() -> void:
	#static_escape_handled = false
#
#func _get_topmost_visible_panel() -> Panel:
	#var topmost: Panel = null
	#var latest_id := -1
#
	#for node in get_tree().get_nodes_in_group("auto_close_panels"):
		#if node.visible:
			#var id := node.get_instance_id()
			#if id > latest_id:
				#latest_id = id
				#topmost = node
#
	#return topmost
