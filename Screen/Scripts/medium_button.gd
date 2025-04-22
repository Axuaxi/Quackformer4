extends Button

func _on_pressed() -> void:
	Global.difficulty = "medium"
	get_parent().update_button_styles()
