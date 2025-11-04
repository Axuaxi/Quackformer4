# BASE ENEMY OBJECT

extends CharacterBody2D
class_name EnemyBase

# Maximum hp for the enemy; default 1 
@export var max_health := 1

# Initial direction for enemy; default left
@export var initial_direction := 1

# Default hp texture for enemy
@export var hp_dot_texture: Texture2D = preload("res://Art/Enemies/hp_icon.png")

#Default empty hp texture for enemy
@export var hp_dot_empty_texture: Texture2D

var hp_bar: HBoxContainer = null

var current_health := 1

# Sets up the enemy
func _ready():
	var sprite = $Sprite2D
	sprite.scale.x *= initial_direction
	current_health = max_health
	add_to_group("enemies")
	# Safely assign the node after tree is ready
	call_deferred("_init_hp_safe")

# Initializes the hp bar
func init_hp_bar() -> void:
	if hp_bar == null:
		return
	hp_bar.visible = true
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.z_index = 100
	hp_bar.custom_minimum_size = Vector2(100, 0)
	hp_bar.add_theme_constant_override("separation", 2)

	for child in hp_bar.get_children():
		child.queue_free()

	for i in range(max_health):
		var dot := TextureRect.new()
		dot.texture = hp_dot_texture
		dot.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dot.custom_minimum_size = Vector2(4, 4)
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hp_bar.add_child(dot)

func _init_hp_safe():
	hp_bar = find_child("HpContainer", true, false) as HBoxContainer
	init_hp_bar()
	update_hp_bar()

@onready var cam := get_viewport().get_camera_2d()
func _process(_dt):
	if hp_bar and cam:
		var screen_pos: Vector2 = cam.unproject_position(global_position + Vector2(0, -24))
		hp_bar.global_position = screen_pos


# Updates the current hp bar
func update_hp_bar() -> void:
	if hp_bar == null:
		return  # Safety check

	for i in range(hp_bar.get_child_count()):
		var dot = hp_bar.get_child(i) as TextureRect
		dot.texture = hp_dot_texture if i < current_health else hp_dot_empty_texture
 	
# Enemy taking damage logic
func take_damage(amount: int) -> void:
	current_health -= amount
	# Red shader visual to indicate that damage has been taken
	flash_red()
	update_hp_bar()
	# Enemy gets deleted from the game and "enemies" group
	if current_health <= 0:
		die()
		remove_from_group("enemies")

# Damage indicator visual
func flash_red():
	if has_node("Sprite2D"):
		var sprite := $Sprite2D
		sprite.modulate = Color(1, 0, 0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)

# Enemy gets released from the queue
func die():
	queue_free()
