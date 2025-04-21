extends TileMapLayer

signal lava_touch
@export var player: Node2D

func _process(delta: float) -> void:
	if not player:
		return

	var tile_pos = local_to_map(player.global_position)
	var data = get_cell_tile_data(tile_pos)

	if data:
		var layer_flags: int = data.get_collision_layer(0)
		if (layer_flags & (1 << 3)) != 0:  # Layer 4
			print("🔥 Player touched lava tile at:", tile_pos)
			emit_signal("lava_touch")
