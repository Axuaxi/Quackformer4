extends CharacterBody2D
class_name EnemyBase

@export var max_health := 1
@export var initial_direction := 1
@export var hp_dot_texture: Texture2D = preload("res://Art/Enemies/hp_icon.png")
@export var hp_dot_empty_texture: Texture2D

var hp_bar: HBoxContainer = null

var current_health := 1

func _ready():
	var sprite = $Sprite2D
	sprite.scale.x *= initial_direction
	current_health = max_health
	add_to_group("enemies")
	# Safely assign the node after tree is ready
	call_deferred("_init_hp_safe")

func init_hp_bar() -> void:
	if hp_bar == null:
		return

	hp_bar.add_theme_constant_override("separation", 1)
	for child in hp_bar.get_children():
		child.queue_free()

	for i in max_health:
		var dot := TextureRect.new()
		dot.texture = hp_dot_texture
		dot.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dot.custom_minimum_size = Vector2(4, 4)
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hp_bar.add_child(dot)

func _init_hp_safe():
	hp_bar = find_child("HpContainer", true, false)
	if hp_bar == null:
		print("❌ Still no HpContainer found on", self)
	else:
		print("✅ HpContainer found on", self)
		# ✅ Only init once max_health is set correctly
		if max_health > 1 or max_health != 1:
			init_hp_bar()

func update_hp_bar() -> void:
	if hp_bar == null:
		return  # Safety check

	for i in range(hp_bar.get_child_count()):
		var dot = hp_bar.get_child(i) as TextureRect
		dot.texture = hp_dot_texture if i < current_health else hp_dot_empty_texture
 	
func take_damage(amount: int) -> void:
	current_health -= amount
	flash_red()
	update_hp_bar()
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
