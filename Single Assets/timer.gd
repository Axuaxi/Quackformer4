extends Node2D

@onready var label: Label = $Label
var total_time := 0.0

func _process(delta: float) -> void:
	var player = get_node("/root/Game/Player")
	if player.dialogue_active:
		return  # ⏸ Pause timer if dialogue is active

	total_time += delta

	var minutes := int(total_time) / 60
	var seconds := int(total_time) % 60
	var tenths := int((total_time - int(total_time)) * 10)

	label.text = "%02d:%02d.%d" % [minutes, seconds, tenths]
