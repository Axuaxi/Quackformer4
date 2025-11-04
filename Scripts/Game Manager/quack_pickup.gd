# Script controlling the floating quack pickupable in the level

extends Area2D

# How fast it floats
@export var float_speed := 1.5
# How high it floats
@export var float_height := 6.0

var base_y := 0.0
var time := 0.0

# Unlocks the quack signal
signal quack_unlocked

# Setup
func _ready() -> void:
	base_y = global_position.y

# Processes the animation
func _process(delta: float) -> void:
	time += delta
	global_position.y = base_y + sin(time * float_speed) * float_height

# Once picked up, then unlock the quack
func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		print("Quack unlocked")
		quack_unlocked.emit()

		# TileMapLayer3
		var tilemap = get_node_or_null("../../TileMapLayer3")
		if tilemap:
			tilemap.visible = false
			tilemap.queue_free()

		# Swap labels
		var label1 = get_node_or_null("../../Label")
		var label2 = get_node_or_null("../../Label2")
		if label1 and label2:
			label1.visible = false
			label2.visible = true

		queue_free()
