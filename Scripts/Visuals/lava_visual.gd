# Script controlling the sprite of the lava

extends Node2D

signal lava_touched

@onready var area = $Area2D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	
# If the player touched it then emit that it touched the player
func _on_body_entered(body: Node) -> void:
	if body.name == "Player":  
		lava_touched.emit()
