extends Area2D

@export var float_speed := 1.5
@export var float_height := 6.0

var base_y := 0.0
var time := 0.0

signal quack_unlocked

func _ready() -> void:
	base_y = global_position.y

func _process(delta: float) -> void:
	time += delta
	global_position.y = base_y + sin(time * float_speed) * float_height

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		print("Quack unlocked")
		quack_unlocked.emit()

		# 🚫 Hide TileMapLayer3
		var tilemap = get_node_or_null("../../TileMapLayer3")
		if tilemap:
			tilemap.visible = false
			tilemap.queue_free()
			print("🧱 TileMapLayer3 hidden!")

		# 🔄 Swap labels
		var label1 = get_node_or_null("../../Label")
		var label2 = get_node_or_null("../../Label2")
		if label1 and label2:
			label1.visible = false
			label2.visible = true
			print("🔤 Label swap complete!")

		queue_free()
