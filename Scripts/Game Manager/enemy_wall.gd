extends Node

@onready var blocker := $TileMapLayer3  # Make sure this is the TileMap node

func _process(delta: float) -> void:
	if blocker.visible and get_tree().get_nodes_in_group("enemies").is_empty():
		blocker.visible = false
		blocker.queue_free()
		print("🧱 TileMapLayer3 removed! All enemies defeated.")
		set_process(false)
