extends Node2D

signal lava_touched

@onready var area = $Area2D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":  # or use a group/tag
		print("🔥 Lava touched player!")
		lava_touched.emit()
