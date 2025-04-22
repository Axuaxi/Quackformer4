extends Button

func _on_pressed() -> void:
	Global.difficulty = "hardcore"
	get_parent().update_button_styles()
