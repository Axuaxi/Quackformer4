extends Button

func _on_pressed() -> void:
	Global.difficulty = "easy"
	get_parent().update_button_styles()
