# Script controlling the wall that blocks the player from exiting until all of the enemies have been defeated

extends Node

@onready var blocker := $TileMapLayer3

# Removes the wall blocking the player from progressing once all enemies have been defeated. 
func _process(delta: float) -> void:
	if blocker.visible and get_tree().get_nodes_in_group("enemies").is_empty():
		blocker.visible = false
		blocker.queue_free()
		set_process(false)
