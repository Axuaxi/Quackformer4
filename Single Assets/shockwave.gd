# Script controlling the shockwave attack from the boss

extends Area2D

# Shockwave params
@export var start_speed := 0
@export var acceleration := 500
@export var max_speed := 2000
var direction := Vector2.RIGHT
var speed := 0.0
var has_hit := false


# Sets up default params on start
func _ready() -> void:
	has_hit = false
	$CollisionPolygon2D.disabled = false
	$GPUParticles2D.emitting = true
	
	# If we try to summon a shockwave and the boss is dead then do nothing
	var boss = get_boss()
	if boss and boss.dead:
		queue_free()
		return
	
	# Simple modulate animation for the shockwave to blink 
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1)

# Calculate and execute the speed and position of the shockwave on game update
func _process(delta: float) -> void:
	speed = min(speed + acceleration * delta, max_speed)
	position += direction.normalized() * speed * delta

# Shockwave collision:
func _on_body_entered(body: Node) -> void:
	# If shockwave collides with the boss then do nothing and disappear
	var boss = get_boss()
	if boss and boss.dead:
		queue_free()
		return
	
	# If shockwave touches the player AND the player hasn't been hit by the shockwave already then 
	# Do damage and disappear (to avoid getting 1 tapped cus the shockwave hits 50000 times in a frame 
	# Or something of the sort)
	if body.name == "Player" and not has_hit:
		has_hit = true

		if body.has_method("take_damage"):
			if "killed_by_shockwave" in body:
				# Sets special death param here for the boss to trigger specific death dialogue
				body.killed_by_shockwave = true
			body.take_damage(1)


# Starts the shockwave's disappearing animation for when it travels its full length
func _start_fade_and_die():
	$GPUParticles2D.emitting = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.05)
	tween.tween_callback(self.queue_free)

# Grabs the boss node that the shockwave is set to, else null
func get_boss():
	var level_root := get_node_or_null("/root/Game/CurrentLevel")
	return level_root.get_child(0).get_node_or_null("Boss") if level_root else null
