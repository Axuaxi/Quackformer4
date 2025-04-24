extends EnemyBase
class_name Cow

@export var speed := 100
@export var acceleration := 300
@export var friction := 300
@export var gravity := 1000
@export var jump_strength := -320
@export var can_jump := false

@onready var player = get_node("/root/Game/Player")
@onready var sprite = $Sprite2D

var quack_check_cooldown := 0.0
var jump_chance := 0.3  # Will be randomized per spawn

func setup_with_stats(wave: int) -> void:
	# Base scaling from wave
	speed *= 1.0 + (wave - 1) * 0.1
	max_health += 1

	# Randomize all stats ±30%
	speed *= randf_range(0.7, 1.3)
	speed = min(speed, 100) # Clamp it to 100
	jump_strength *= randf_range(0.7, 1)
	acceleration *= randf_range(0.5, 1.5)
	friction *= randf_range(0.5, 1.5)
	gravity *= randf_range(0.7, 1)
	jump_chance = randf_range(0.1, 0.3)  # Optional: widen if you like

	# Randomize and ceil HP
	var health_multiplier = max_health * randf_range(0.7, 1.3)
	if randi() % 2 == 0:
		max_health = floor(health_multiplier)
	else:
		max_health = ceil(health_multiplier)

	current_health = max_health
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
	if area:
		print("🎯 Connecting body_entered signal...")
		if not area.is_connected("body_entered", Callable(self, "_on_body_entered")):
			area.connect("body_entered", Callable(self, "_on_body_entered"))
			print("✅ Connected successfully.")
		else:
			print("⚠️ Already connected.")

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

	# Check for quack proximity with cooldown
	if is_on_floor():
		# 🐣 Big jump if far below player
		if abs(player.global_position.y - global_position.y) > 100 and can_jump:
			if randf() < 0.003:
				print("🪜 Cow is far below player — random big jump!")
				velocity.y = jump_strength * 2

		elif can_jump and quack_check_cooldown <= 0.0:
			var quack_nearby := false
			for quack in get_tree().get_nodes_in_group("quacks"):
				if abs(quack.global_position.x - global_position.x) <= 100 and abs(quack.global_position.y - global_position.y) <= 30:
					quack_nearby = true
					break

			if quack_nearby and randf() < jump_chance:
				print("🐮 Cow reacts to nearby quack and jumps!")
				velocity.y = jump_strength

			quack_check_cooldown = 0.5  # Reset regardless of jump

		var quack_nearby := false
		for quack in get_tree().get_nodes_in_group("quacks"):
			if abs(quack.global_position.x - global_position.x) <= 100 and abs(quack.global_position.y - global_position.y) <= 30:
				quack_nearby = true
				break

		if quack_nearby:
			if randf() < jump_chance:
				print("🐮 Cow reacts to nearby quack and jumps!")
				velocity.y = jump_strength

			# Reset cooldown because a quack was nearby (regardless of jump)
			quack_check_cooldown = 0.5

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

# Collision responses
func _on_body_entered(body: Node) -> void:
	print("🐮 Body entered cow:", body.name)
	print("🔥 ANYTHING entered cow area:", body)
	if body.name == "Player":
		body.take_damage(1)
		print("🐮 Cow landed on player!")
		if is_on_floor():
			velocity.y = jump_strength
