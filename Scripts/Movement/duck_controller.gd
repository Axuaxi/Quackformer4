extends CharacterBody2D

# --- Movement ---
@export var speed := 200
@export var acceleration := 500
@export var friction := 900
@export var gravity := 1000
@export var jump_speed := -300
@export var max_jumps := 2

# --- Wall Jump ---
@export var wall_jump_force := Vector2(200, -350)
@export var wall_jump_coyote_time := 0.15

# --- Quack Projectile ---
@export var quack_projectile_scene: PackedScene
@export var quack_cooldown := 1.0

# --- Internal State ---
@onready var sprite = $Sprite2D
var jumps_left := 0
var wall_jump_timer := 0.0
var wall_dir := 0
var touching_wall := false

var can_quack := false
var quack_time_left := 0.0

var dialogue_active := false

func _ready():
	jumps_left = max_jumps
	quack_time_left = 0.0

func _physics_process(delta: float) -> void:
	if dialogue_active:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.y += gravity * delta
		move_and_slide()
		return

	_handle_movement(delta)
	_handle_quack(delta)
	check_lava_collision()

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("left", "right")

	# Horizontal movement
	if input_dir != 0.0:
		var target_velocity_x := input_dir * speed
		velocity.x = move_toward(
			velocity.x, target_velocity_x,
			acceleration * (5.0 if sign(velocity.x) != 0 and sign(velocity.x) != sign(target_velocity_x) else 1.0) * delta
		)
		sprite.scale.x = sign(input_dir)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# Gravity
	velocity.y += gravity * delta

	# Wall detection
	touching_wall = false
	wall_dir = 0
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var normal = col.get_normal()
		if abs(normal.x) > 0.0:
			touching_wall = true
			wall_dir = -sign(normal.x)

	wall_jump_timer = wall_jump_coyote_time if touching_wall else wall_jump_timer - delta

	# Jumping
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_speed
			jumps_left -= 1
		elif wall_jump_timer > 0:
			print("Wall jump!")
			velocity.x = -wall_dir * abs(wall_jump_force.x)
			velocity.y = wall_jump_force.y
			wall_jump_timer = 0
		elif jumps_left > 1:
			velocity.y = jump_speed
			jumps_left -= 1

	# Reset jump count when touching ground or wall
	if is_on_floor() or touching_wall:
		jumps_left = max_jumps
		if is_on_floor() and velocity.y > 0:
			velocity.y = 0

	# Wall slide
	if touching_wall and not is_on_floor() and velocity.y > 0:
		velocity.y = min(velocity.y, 100)

	move_and_slide()

func _handle_quack(delta: float) -> void:
	if quack_time_left > 0.0:
		quack_time_left = max(quack_time_left - delta, 0.0)

	if Input.is_action_just_pressed("quack") and can_quack and quack_time_left == 0.0:
		shoot_quack()
		quack_time_left = quack_cooldown

func shoot_quack():
	print("🐣 Quack fired!")
	if quack_projectile_scene:
		var quack = quack_projectile_scene.instantiate()
		var facing = Vector2.RIGHT * sprite.scale.x
		quack.global_position = global_position + facing * 20
		quack.direction = facing
		get_tree().current_scene.add_child(quack)
	else:
		print("❌ Quack projectile scene not set.")

func _on_quack_unlocked() -> void:
	can_quack = true
	print("✅ Quack unlocked!")

func check_lava_collision() -> void:
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider.name == "TileMapLayer2":
			print("🔥 Touched lava!")
			die_and_restart()

func die_and_restart():
	if Global.game_over:
		return
	Global.game_over = true
	for quack in get_tree().get_nodes_in_group("quacks"):
		quack.queue_free()
	for shockwave in get_tree().get_nodes_in_group("shockwaves"):
		shockwave.queue_free()
	for shuriken in get_tree().get_nodes_in_group("shurikens"):
		shuriken.queue_free()
		
	get_node("/root/Game").load_level(get_node("/root/Game").current_level_index)

func die_with_boss_dialogue(lines_: Array[String]) -> void:
	if Global.game_over:
		return
	Global.game_over = true
	
	for quack in get_tree().get_nodes_in_group("quacks"):
		quack.queue_free()

	dialogue_active = true
	visible = false
	collision_layer = collision_layer & ~1

	GlobalDialogue.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	GlobalDialogue.start_dialogue(lines_)
	await GlobalDialogue.dialogue_finished

func _on_dialogue_finished() -> void:
	dialogue_active = false
	visible = true
	collision_layer = collision_layer | 1
	get_node("/root/Game").load_level(get_node("/root/Game").current_level_index)
