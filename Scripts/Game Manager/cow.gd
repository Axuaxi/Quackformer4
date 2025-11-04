# Script for the cow enemy and all of its params and behaviours

extends EnemyBase
class_name Cow

@export var speed := 85
@export var acceleration := 300
@export var friction := 300
@export var gravity := 1000
@export var jump_strength := -320
@export var can_jump := false

@onready var player = get_node("/root/Game/Player")
@onready var sprite = $Sprite2D

var quack_check_cooldown := 0.0
var jump_chance := 0.5
var big_jump_timer := 0.0

# Setup the random stats
func setup_with_stats(wave: int) -> void:
	big_jump_timer = randf_range(3.0, 10.0)
	speed *= 1.0 + (wave - 1) * 0.1
	max_health = 1 + wave
	max_health = floor(max_health * ceil(randf_range(0.7, 1.3)))
	max_health = min(max_health, 5)
	speed *= randf_range(0.5, 1.8)
	speed = min(speed, 90)
	jump_strength *= randf_range(0.7, 1.0)
	acceleration *= randf_range(0.5, 1.2)
	friction *= randf_range(0.5, 1.2)
	jump_chance = randf_range(0.15, 0.3)
	can_jump = true
	current_health = max_health
	init_hp_bar()
	setup()

# Setup 
func setup() -> void:
	add_to_group("enemies")
	set_physics_process(true)
	set_process(true)
	current_health = max_health
	update_hp_bar()
	var area := $Area2D
	if area and not area.is_connected("body_entered", Callable(self, "_on_body_entered")):
		area.connect("body_entered", Callable(self, "_on_body_entered"))

# Processes the cow
func _process(delta: float) -> void:
	if player == null:
		return

	var target_x = player.global_position.x
	var direction = sign(target_x - global_position.x)
	var target_speed = direction * speed

	if direction != 0:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	position.x += velocity.x * delta
	velocity.y += gravity * delta

	quack_check_cooldown -= delta
	big_jump_timer -= delta
	
	# Big jump if the cow is far below the player
	if is_on_floor() and can_jump and big_jump_timer <= 0.0:
		if abs(player.global_position.y - global_position.y) > 100:
			velocity.y = jump_strength * 1.7
			big_jump_timer = randf_range(3.0, 10.0)

	# Cow has a chance to jump to attempt to dodge the quack attack
	if is_on_floor() and can_jump and quack_check_cooldown <= 0.0:
		for quack in get_tree().get_nodes_in_group("quacks"):
			var dx = abs(quack.global_position.x - global_position.x)
			var dy = abs(quack.global_position.y - global_position.y)
			if dx <= 100 and dy <= 30:
				# Cow will try to jump if the rolled number is less than the chance
				if randf() < jump_chance:
					velocity.y = jump_strength
				quack_check_cooldown = 0.5
				break

	if is_on_floor() and velocity.y > 0:
		velocity.y = 0

	if velocity.x != 0:
		sprite.scale.x = sign(velocity.x)

	move_and_slide()

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider != self and collider.is_in_group("enemies"):
			var normal := collision.get_normal()
			if abs(normal.x) > 0.8 and abs(normal.y) < 0.5:
				velocity.x = 0
	
	# Cow will jump if it hits a wall
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if abs(collision.get_normal().x) > 0.8 and is_on_floor():
			velocity.y = jump_strength

	for cow in get_tree().get_nodes_in_group("enemies"):
		if cow != self and position.distance_to(cow.position) < 16:
			var push_dir = (position - cow.position).normalized()
			position += push_dir * 0.5 * delta

# Damage player
func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.take_damage(1)
		if is_on_floor():
			velocity.y = jump_strength
