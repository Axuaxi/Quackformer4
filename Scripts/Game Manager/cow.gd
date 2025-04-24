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
var jump_chance := 0.5  # For testing: always jumps if quack nearby
var big_jump_timer := 0.0

func setup_with_stats(wave: int) -> void:
	big_jump_timer = randf_range(3.0, 10.0)
	speed *= 1.0 + (wave - 1) * 0.1
	max_health = wave + randi() % 4 - 1

	speed *= randf_range(0.7, 1.1)
	speed = min(speed, 95)
	jump_strength *= randf_range(0.7, 1.0)
	acceleration *= randf_range(0.5, 1.2)
	friction *= randf_range(0.5, 1.2)
	jump_chance = randf_range(0.3, 0.7)
	can_jump = true

	var health_multiplier = max_health * randf_range(0.7, 1.3)
	if randi() % 2 == 0:
		max_health = floor(health_multiplier)
	else:
		max_health = ceil(health_multiplier)

	current_health = max_health
	init_hp_bar()
	update_hp_bar()
	setup()

func setup() -> void:
	print("🐮 Cow setup called")
	add_to_group("enemies")
	set_physics_process(true)
	set_process(true)
	current_health = max_health
	update_hp_bar()

	var area := $Area2D
	if area and not area.is_connected("body_entered", Callable(self, "_on_body_entered")):
		area.connect("body_entered", Callable(self, "_on_body_entered"))
		print("✅ Connected successfully.")

func _process(delta: float) -> void:
	if player == null:
		return

	# Movement logic
	var target_x = player.global_position.x
	var direction = sign(target_x - global_position.x)
	var target_speed = direction * speed

	if direction != 0:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	position.x += velocity.x * delta
	velocity.y += gravity * delta

	# Update cooldown timer
	quack_check_cooldown -= delta

		# Check for height difference
		# Update big jump cooldown
	big_jump_timer -= delta

	# Jump if far below player, but only once every 3–10 seconds
	if is_on_floor() and can_jump and big_jump_timer <= 0.0:
		if abs(player.global_position.y - global_position.y) > 100:
			print("🪜 Cow is far below player — jumping up!")
			velocity.y = jump_strength * 1.7
			big_jump_timer = randf_range(3.0, 10.0)  # Reset timer


	# React to nearby quack
	if is_on_floor() and can_jump and quack_check_cooldown <= 0.0:
		for quack in get_tree().get_nodes_in_group("quacks"):
			var dx = abs(quack.global_position.x - global_position.x)
			var dy = abs(quack.global_position.y - global_position.y)
			if dx <= 100 and dy <= 30:
				if randf() < jump_chance:
					print("🐮 Jumping! Chance:", jump_chance)
					velocity.y = jump_strength 
				else:
					print("🐮 Ignored quack. Chance:", jump_chance)
				quack_check_cooldown = 0.5
				break


	# Vertical velocity reset when landing
	if is_on_floor() and velocity.y > 0:
		velocity.y = 0

	# Flip sprite based on direction
	if velocity.x != 0:
		sprite.scale.x = sign(velocity.x)

	# Apply movement and resolve collisions
	move_and_slide()

	# Wall jump logic
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if abs(collision.get_normal().x) > 0.8:
			if is_on_floor():
				print("🐮 Cow hit wall — jumping!")
				velocity.y = jump_strength



	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if abs(collision.get_normal().x) > 0.8 and is_on_floor():
			print("🐮 Cow hit wall — jumping!")
			velocity.y = jump_strength

func _on_body_entered(body: Node) -> void:
	print("🐮 Body entered cow:", body.name)
	if body.name == "Player":
		body.take_damage(1)
		print("🐮 Cow landed on player!")
		if is_on_floor():
			velocity.y = jump_strength
