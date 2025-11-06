# Script controlling the shuriken attack from the boss

extends Area2D

# Default params
@export var start_speed := 0
@export var acceleration := 1000
@export var max_speed := 500
@export var lifetime := 3.0

# degrees per frame
@export var spin_speed := -5  

var direction := Vector2.RIGHT
@onready var player = get_node_or_null("/root/Game/Player")

var speed := 0
var has_hit := false

# Set default params
func _ready():
	add_to_group("shurikens")
	$CollisionShape2D.disabled = false
	$GPUParticles2D.emitting = true
	has_hit = false
	
	# If the boss is dead then delete and do nothing
	var boss = get_boss()
	if boss and boss.dead:
		queue_free()
	
	# Lock in direction at spawn
	if is_instance_valid(player):
		direction = (player.global_position - global_position).normalized()

	# Rotate initial orientation to face direction (optional)
	rotation = direction.angle()

	# If the shuriken has run out of time then fade and disappear
	if lifetime > 0:
		await get_tree().create_timer(lifetime).timeout
		_start_fade_and_die()

# Calculates the movement of the shurikens every game update
func _process(delta: float) -> void:
	# Move forward
	speed = min(speed + acceleration * delta, max_speed)
	position += direction.normalized() * speed * delta

	# Spin
	rotation += deg_to_rad(spin_speed)

# If the shurikens touch the player then start to fade and die if we havent been hit, otherwise pass thru
func _on_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		if has_hit:
			return
		else:
			_start_fade_and_die()

# If we've not been hit by the attack already and it collides with us tne take 1 damage, then disappear
# Otherwise if the collision is a tilemap then just disappear immediately
func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and not has_hit:
		has_hit = true
		if body.has_method("take_damage"):
			# Marks the death cause here for the boss to trigger special dialogue
			body.killed_by_shuriken = true
			body.take_damage(1)
		_start_fade_and_die()
	elif body is TileMapLayer:
		_start_fade_and_die()

# Shurikens will fade away here and disappear
func _start_fade_and_die():
	$GPUParticles2D.emitting = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.05)
	tween.tween_callback(self.queue_free)
	
# Grabs the boss node the shuriken is associated with
func get_boss():
	var level_root := get_node_or_null("/root/Game/CurrentLevel")
	return level_root.get_child(0).get_node_or_null("Boss") if level_root else null
