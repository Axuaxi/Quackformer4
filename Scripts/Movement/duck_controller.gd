# Player Controller (TODO: Make it modular)

extends CharacterBody2D

# --- CONFIG ---
@export var speed := 200
@export var acceleration := 500
@export var friction := 900
@export var gravity := 1000
@export var jump_speed := -300
@export var max_jumps := 2
@export var wall_jump_force := Vector2(200, -350)
@export var wall_jump_coyote_time := 0.15

# --- QUACK ---
@export var quack_projectile_scene: PackedScene
@export var quack_cooldown := 1.0
@export var can_quack := false
@export var quack_dot_texture: Texture2D = preload("res://Art/Duck/quack_icon.png")
@export var quack_dot_empty_texture: Texture2D

# --- HEALTH ---
@export var max_health := 1
@export var hp_dot_texture: Texture2D = preload("res://Art/Enemies/hp_icon.png")
@export var hp_dot_empty_texture: Texture2D
@export var iframe_duration := 0.5

# --- NODES ---
@onready var sprite = $Sprite2D
@onready var hp_bar: HBoxContainer = $HpContainer
@onready var quack_bar: HBoxContainer = $QuackContainer
@onready var player_material := $Sprite2D.material as ShaderMaterial

# --- STATE ---
var current_health := max_health
var jumps_left := 0
var wall_jump_timer := 0.0
var wall_dir := 0
var touching_wall := false
var quack_time_left := 0.0
var blink_timer := 0.0
var dialogue_active := false
var is_invincible := false
var killed_by_shuriken := false
var killed_by_shockwave := false
var in_water := false
var swim_jump_cooldown := 0.0

# Collision layer 9 (index starts at 0)
const WATER_LAYER := 1 << 8  

# --- READY ---
func _ready():
	# Setup the players hp in relation to the difficulty
	match Global.difficulty:
		"easy": max_health = 3
		"medium": max_health = 2
		"hard", "hardcore": max_health = 1
		_: max_health = 1
	
	# Setup the base stats
	jumps_left = max_jumps
	current_health = max_health
	quack_time_left = 0.0
	init_hp_bar()
	init_quack_bar()
	update_quack_bar()
	quack_bar.visible = false
	quack_bar.position.y -= 1
	
# --- PHYSICS ---
# Processes the physics here
func _physics_process(delta: float) -> void:
	# If the dialogue box is active, then stop horiz movement 
	if dialogue_active:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.y += gravity * delta
		move_and_slide()
		return
	
	# Handles the different types of movement and collision
	in_water = _is_in_water()
	_handle_movement(delta)
	_handle_quack(delta)
	_handle_idle(delta)
	_handle_cooldown_shader(delta)
	check_lava_collision()
	# Swimming physics cooldown (TODO: Polish it cus it feels odd lowkey)
	swim_jump_cooldown = max(swim_jump_cooldown - delta, 0.0)

# --- MOVEMENT ---
func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("left", "right")

	# --- Horizontal Movement ---
	if input_dir != 0.0:
		var target_velocity_x := input_dir * speed
		velocity.x = move_toward(
			velocity.x, target_velocity_x,
			acceleration * (5.0 if sign(velocity.x) != 0 and sign(velocity.x) != sign(target_velocity_x) else 1.0) * delta
		)
		sprite.scale.x = sign(input_dir)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# --- Vertical Movement ---
	if in_water:
		if Input.is_action_pressed("jump"):
			velocity.y = move_toward(velocity.y, -speed, acceleration * delta)
			# Prevent buoyancy override
			swim_jump_cooldown = 0.2  
		elif Input.is_action_pressed("down"):
			velocity.y = move_toward(velocity.y, speed, acceleration * delta)
		elif swim_jump_cooldown <= 0.0:
			velocity.y = move_toward(velocity.y, -200, acceleration * delta)
	else:
		velocity.y += gravity * delta

	# --- Wall Detection ---
	touching_wall = false
	wall_dir = 0
	# Stops the duck from going thru walls ostts
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var normal = col.get_normal()
		if abs(normal.x) > 0.0:
			touching_wall = true
			wall_dir = -sign(normal.x)

	# Wall jumping timer here
	wall_jump_timer = wall_jump_coyote_time if touching_wall else wall_jump_timer - delta

	# --- Jumping ---
	if Input.is_action_just_pressed("jump"):
		# If were on the floor jump normally
		if is_on_floor():
			velocity.y = jump_speed
			jumps_left -= 1
		# If the wall jumping timer is greater than 0 then wall jump
		elif wall_jump_timer > 0:
			velocity.x = -wall_dir * abs(wall_jump_force.x)
			velocity.y = wall_jump_force.y
			wall_jump_timer = 0
		# Otherwise do a double jump if we still have those left
		elif jumps_left > 1:
			velocity.y = jump_speed
			jumps_left -= 1

	# --- Reset Jumps ---
	if is_on_floor() or touching_wall:
		jumps_left = max_jumps
		# Reset the y velo
		if is_on_floor() and velocity.y > 0:
			velocity.y = 0

	# --- Wall Slide ---
	if not in_water and touching_wall and not is_on_floor() and velocity.y > 0:
		velocity.y = min(velocity.y, 100)

	move_and_slide()

	
# --- QUACK ---
func _handle_quack(delta: float) -> void:
	# If the quack cd still has time left then continue ticking down
	if quack_time_left > 0.0:
		quack_time_left = max(quack_time_left - delta, 0.0)
		if quack_time_left == 0.0:
			# Shader for when the player has reloaded a quack (TODO: Make this work it doesnt work atm)
			blink_timer = 0.3
			player_material.set_shader_parameter("time_passed", 0.0)

	# Allows the player to shoot if the quack cd is over
	if Input.is_action_just_pressed("quack") and can_quack and quack_time_left == 0.0:
		shoot_quack()
		quack_time_left = quack_cooldown

	update_quack_bar()

# Shoots the quack projectile
func shoot_quack():
	if quack_projectile_scene:
		var quack = quack_projectile_scene.instantiate()
		var facing = Vector2.RIGHT * sprite.scale.x
		quack.global_position = global_position + facing * 20
		quack.direction = facing
		get_tree().current_scene.add_child(quack)

# Allows the player to shoot quacks now that theyve unlocked it
func _on_quack_unlocked() -> void:
	can_quack = true
	init_quack_bar()
	update_quack_bar()
	quack_bar.visible = true

# --- UI ---
func _handle_idle(delta: float) -> void:
	var input_vector = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("jump")
	)
	var is_idle = input_vector == Vector2.ZERO
	player_material.set_shader_parameter("is_idle", is_idle)

# Cooldown shader for reload quack (TODO: MAKE THIS WORK)
func _handle_cooldown_shader(delta: float) -> void:
	if player_material == null:
		return

	if blink_timer > 0.0:
		player_material.set_shader_parameter("blink_strength", 1.0)
		var new_time: int = player_material.get_shader_parameter("time_passed") + delta
		player_material.set_shader_parameter("time_passed", new_time)
		blink_timer -= delta
	else:
		player_material.set_shader_parameter("blink_strength", 0.0)

# Initializes the players hp bar
func init_hp_bar() -> void:
	hp_bar.add_theme_constant_override("separation", 1)
	# Gets rid of any current hp bar icon
	for child in hp_bar.get_children():
		child.queue_free()
	# Creates the hp bar from scratch
	for i in max_health:
		var dot := TextureRect.new()
		dot.texture = hp_dot_texture
		dot.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dot.custom_minimum_size = Vector2(4, 4)
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hp_bar.add_child(dot)

# Updates the hp bar
func update_hp_bar() -> void:
	for i in hp_bar.get_child_count():
		var dot = hp_bar.get_child(i) as TextureRect
		dot.texture = hp_dot_texture if i < current_health else hp_dot_empty_texture

# Initializes the quack bar from scratch 
func init_quack_bar() -> void:
	quack_bar.add_theme_constant_override("separation", 1)
	for child in quack_bar.get_children():
		child.queue_free()
	var dot := TextureRect.new()
	dot.texture = quack_dot_texture
	dot.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dot.custom_minimum_size = Vector2(4, 4)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	quack_bar.add_child(dot)

# Updates the quack bar
func update_quack_bar() -> void:
	# Hide if cant quack
	if not can_quack:
		quack_bar.visible = false
		return
	quack_bar.visible = true
	if quack_bar.get_child_count() == 0:
		return
	var dot := quack_bar.get_child(0) as TextureRect
	if dot == null:
		return
	dot.texture = quack_dot_texture if quack_time_left == 0.0 else quack_dot_empty_texture

# --- DAMAGE ---
func take_damage(amount: int) -> void:
	# If were invincible or game is over then do nothing
	if Global.game_over or is_invincible:
		return
	# Otherwise take "amount" in damage and update the hp bar and the damage shader
	current_health -= amount
	update_hp_bar()
	flash_red()
	start_iframes()
	# If we are dead then restart and if we died to the boss have him taunt us with dialogue
	if current_health <= 0:
		die_and_restart()
		if killed_by_shuriken:
			killed_by_shuriken = false
			die_with_boss_dialogue(["Imbecile."])
		elif killed_by_shockwave:
			killed_by_shockwave = false
			die_with_boss_dialogue(["Fool."])

# Starts the i frames
func start_iframes() -> void:
	is_invincible = true
	await get_tree().create_timer(iframe_duration).timeout
	is_invincible = false

# Flash red to show that weve taken damage
func flash_red():
	if has_node("Sprite2D"):
		var sprite := $Sprite2D
		var mat := sprite.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("flash_strength", 1.0)
			var tween := create_tween()
			tween.tween_property(mat, "shader_parameter/flash_strength", 0.0, 0.2)


# --- DEATH ---
# Resets everything and restarts the game
func die_and_restart():
	if Global.game_over:
		return
	Global.game_over = true
	velocity.y = 0
	for group in ["quacks", "shockwaves", "shurikens", "eggs", "enemies"]:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()
	if Global.difficulty != "hardcore":
		get_node("/root/Game").load_level(get_node("/root/Game").current_level_index)
	else:
		get_node("/root/Game").current_level_index = 0
		can_quack = false
		get_node("/root/Game").load_level(0)
	await get_tree().create_timer(0.1).timeout
	Global.game_over = false

# Dies with boss dialogue
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
	await get_tree().create_timer(1).timeout

# Resets once the boss dialogue finished
func _on_dialogue_finished() -> void:
	dialogue_active = false
	visible = true
	collision_layer = collision_layer | 1
	if Global.difficulty != "hardcore":
		get_node("/root/Game").load_level(get_node("/root/Game").current_level_index)
	else:
		get_node("/root/Game").current_level_index = 0
		can_quack = false
		get_node("/root/Game").load_level(0)

# --- LAVA CHECK ---
# Checks the lava collision
func check_lava_collision() -> void:
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider.name == "TileMapLayer2":
			# If not hardcore then restart level
			if Global.difficulty != "hardcore":
				get_node("/root/Game").load_level(get_node("/root/Game").current_level_index)
			# If hardcore restart game
			else:
				get_node("/root/Game").current_level_index = 0
				can_quack = false
				get_node("/root/Game").load_level(0)
				
# --- WATER CHECK ---
func _is_in_water() -> bool:
	var space_state = get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = WATER_LAYER
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_point(query, 1)
	return result.size() > 0
