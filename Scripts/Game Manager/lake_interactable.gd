extends Area2D

@onready var exit := get_parent().get_node_or_null("Exit")
@onready var label1 := get_parent().get_node_or_null("Label")
@onready var label2 := get_parent().get_node_or_null("Label2")

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Quack":
		visible = false
		var tween := create_tween()
		
		if exit:
			exit.interactive_done = true
		
		# Fade out label1
		if label1:
			tween.tween_property(label1, "modulate:a", 0.0, 0.5)

		# Fade in label2
		if label2:
			label2.modulate.a = 0.0  # Start fully transparent
			label2.visible = true
			tween.tween_property(label2, "modulate:a", 1.0, 0.5)

		await tween.finished

		queue_free()
