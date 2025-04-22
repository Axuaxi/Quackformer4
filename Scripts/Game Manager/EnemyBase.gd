# EnemyBase.gd
extends CharacterBody2D
class_name EnemyBase  # 🌟 This registers it globally

@export var max_health := 1
@export var initial_direction := 1
var current_health := 1

func _ready():
	var sprite = $Sprite2D
	sprite.scale.x *= initial_direction
	current_health = max_health
	add_to_group("enemies")

func take_damage(amount: int) -> void:
	current_health -= amount
	flash_red()
	if current_health <= 0:
		die()
		remove_from_group("enemies")

func flash_red():
	if has_node("Sprite2D"):
		var sprite := $Sprite2D
		sprite.modulate = Color(1, 0, 0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)

func die():
	queue_free()
