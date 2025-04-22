extends Button

func _on_pressed() -> void:
	Global.difficulty = "hard"
	get_parent().update_button_styles()
