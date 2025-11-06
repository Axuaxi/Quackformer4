# Script controlling Sir Oinksalot - the first boss

extends CharacterBody2D

# --- CONFIG ---
@export var max_health := 10
@export var speed := 200
@export var gravity := 1000
@export var jump_strength := -450
@export var slam_interval := 2.0
@export var shuriken_scene: PackedScene
@export var dialogue_box_scene: PackedScene = preload("res://Screen/UI/DialogueBox.tscn")
@export var hp_dot_texture: Texture2D
@export var hp_dot_empty_texture: Texture2D

# --- NODES ---
@onready var player: Node2D = get_node("/root/Game/Player")
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var hp_bar: HBoxContainer = $HpContainer

# --- STATE ---
var is_slamming := false
var floored := false
var current_health := max_health
var dialogue_done := false
var dead := false
var must_slam_next := false

# --- READY ---
func _ready() -> void:
	randomize()
	add_to_group("bosses")
	connect("body_entered", Callable(self, "_on_body_entered"))
	hp_bar.add_theme_constant_override("separation", 1)
	attack_timer.stop()
	attack_timer.wait_time = slam_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	init_hp_bar()
	show_intro_dialogue()

	# Connect contact signal
	if has_signal("body_entered"):
		connect("body_entered", Callable(self, "_on_body_entered"))

# --- INIT HP BAR ---
func init_hp_bar() -> void:
	for child in hp_bar.get_children():
		child.queue_free()
	for i in max_health:
		var dot := TextureRect.new()
		dot.texture = hp_dot_texture
		dot.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		hp_bar.add_child(dot)

# --- PHYSICS ---
func _physics_process(delta: float) -> void:
	if dead:
		return

	var gravity_multiplier := 2.0 if is_slamming else 1.0
	velocity.y += gravity * gravity_multiplier * (0.4 if velocity.y < 0 else 3.0) * delta


	move_and_slide()

	if is_on_floor():
		# Spawn shockwave if were slamming and touching the floor
		if is_slamming:
			spawn_shockwave()
			velocity.x = 0
			is_slamming = false 
			
			# Only allow chained slam if on floor (again) and randf() gives us a smaller number than our chance
			if randf() < 0.5:
				await get_tree().create_timer(0.1).timeout
				# Guard again before chaining 
				if is_on_floor(): 
					slam_toward_player_or_random()

		floored = true

	if abs(velocity.x) > 5:
		sprite.scale.x = abs(sprite.scale.x) * sign(velocity.x)

	# Auto slam if on floor, above threshold, and player is invincible (Esentially just if weve already slammed and landed on the player,
	# then we dont want to get the player stuck under the boss so we do another slam)
	if is_on_floor() and global_position.y < -38.0:
		if "is_invincible" in player and player.is_invincible and not is_slamming:
			slam_toward_player_or_random()

# --- COMBAT ---
func _on_attack_timer_timeout() -> void:
	# Stop attacking if we're dead, theres dialogue on screen or the player is dead
	if dead or not dialogue_done or not is_instance_valid(player):
		return
	
	# If were guaranteed to slam attack next then do it
	if must_slam_next:
		must_slam_next = false
		await slam_and_wait()
	# Otherwise, we choose 50/50 between slamming and shurikening
	else:
		if randf() < 0.5:
			await slam_and_wait()
		else:
			throw_shuriken()
			must_slam_next = true
			attack_timer.wait_time = randf_range(2.0, 4.0)
			attack_timer.start()

# Jumps above the player and slams down, then initiate a cooldown timer
func slam_and_wait() -> void:
	slam_toward_player_or_random()
	while is_slamming:
		await get_tree().process_frame
	attack_timer.wait_time = randf_range(1.0, 3.0)
	attack_timer.start()

# Jumps up and slams down fast here, either towards or away form teh player
func slam_toward_player_or_random() -> void:
	if dead or is_slamming:
		return

	is_slamming = true
	floored = false

	var direction := Vector2.RIGHT
	# 75/25 chance to slam towards the player or away (TODO: Just code this to be 7525 instead of 5050 and 5050 again)
	if randf() < 0.5:
		# If we get player then we slam towards their global position
		direction = (player.global_position - global_position).normalized()
	else:
		# Otherwise we have a 50/50 of slamming towards the player or away
		direction = Vector2.LEFT if randi() % 2 == 0 else Vector2.RIGHT

	velocity.x = direction.x * speed * randf_range(0.3, 1.0)
	velocity.y = jump_strength * 1.3

# Throws a random assortment of shurikens at the player
func throw_shuriken() -> void:
	# Do nothing if the boss is dead of shurikens dont exist
	if dead or not shuriken_scene:
		return

	var shuriken_count := randi() % 3 + 1
	fire_shurikens_sequentially(shuriken_count)

# Shoot "count" shurikens one after another
func fire_shurikens_sequentially(count: int) -> void:
	# Do nothing if the boss is dead
	if dead:
		return
	var aim_dir := (player.global_position - global_position).normalized()
	if aim_dir.x != 0:
		sprite.scale.x = abs(sprite.scale.x) * sign(aim_dir.x)
	
	# Fire each shuriken 1 by 1
	for i in count:
		await get_tree().create_timer(0.15).timeout
		var shuriken = shuriken_scene.instantiate()
		shuriken.global_position = global_position
		shuriken.direction = aim_dir
		get_tree().current_scene.add_child(shuriken)

# Spawns a shockwave in front and behind the boss
func spawn_shockwave() -> void:
	# Do nothing if the boss is dead
	if dead:
		return

	# Shakes the camera for a heavier effect
	var cam := get_viewport().get_camera_2d()
	if cam and "shake" in cam:
		cam.shake(5)

	# Spawn in the shockwave object
	var shockwave_scene = preload("res://Single Assets/shockwave.tscn")
	# Shoot one left and one right
	for dir in [Vector2.LEFT, Vector2.RIGHT]:
		var shockwave = shockwave_scene.instantiate()
		shockwave.add_to_group("shockwaves")
		# Offset it from the boss so the collision boxes dont hit each other
		shockwave.global_position = global_position + Vector2(0, -3)
		shockwave.direction = dir
	
		# Scale the sprite of the shockwave to the direction its facing
		var sprite = shockwave.get_node_or_null("Sprite2D")
		if sprite:
			sprite.scale.x = -dir.x
		
		# Add the shockwaves to the global scene so we can mass delete them if we need to
		get_tree().current_scene.add_child(shockwave)

# --- DAMAGE ---
# Boss takes "amount" damage
func take_damage(amount: int) -> void:
	flash_red()
	if dead:
		return
	current_health -= amount
	update_hp_bar()
	if current_health <= 0:
		die()

# Updates the boss's hp bar visual here 
func update_hp_bar() -> void:
	for i in hp_bar.get_child_count():
		var dot = hp_bar.get_child(i) as TextureRect
		dot.texture = hp_dot_texture if i < current_health else hp_dot_empty_texture

# --- CONTACT DAMAGE ---
# Boss contact damage with the player
func _on_body_entered(body: Node) -> void:
	# If the boss is dead then do nothing
	if dead:
		return

	if body.name == "Player" and body.has_method("take_damage"):
		# If player is invincible, slam instead (if on floor)
		if "is_invincible" in body and body.is_invincible:
			if is_on_floor() and not is_slamming:
				slam_toward_player_or_random()
		# Else, make the player take double damage
		else:
			body.take_damage(2)
			if not is_slamming:
				slam_toward_player_or_random()

# --- DEATH ---
# Boss dies and deletes everything in it's arsenal
func die() -> void:
	if dead:
		return
	dead = true
	# Stops attacking
	attack_timer.stop()
	
	# Deletes all current shurikens and shockwaves on screen
	for node in get_tree().get_nodes_in_group("shurikens"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("shockwaves"):
		node.queue_free()

	visible = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	
	# If dialogue box wassnt assigned to the boss then do nohting (TESTING)
	if not dialogue_box_scene:
		push_error("DialogueBox scene not assigned!")
		return

	var dialogue_box := dialogue_box_scene.instantiate()
	get_tree().current_scene.add_child(dialogue_box)
	
	# Only show the dialogue if the player is alive
	if player:
		player.dialogue_active = true
	
	# Dialogue (Death)
	GlobalDialogue.dialogue_finished.connect(_on_death_dialogue_finished.bind(dialogue_box), CONNECT_ONE_SHOT)
	GlobalDialogue.start_dialogue([
		"You-",
		"You-",
		"..."
	])

# --- DIALOGUE ---
# Shows the dialogue intro 
func show_intro_dialogue() -> void:
	GlobalDialogue.dialogue_finished.connect(_on_intro_dialogue_finished, CONNECT_ONE_SHOT)
	GlobalDialogue.start_dialogue([
		"You've made it this far... but you won't leave alive.",
		"I, Sir Oinksalot will personally see to your demise.",
		"Prepare yourself, DUCK!"
	])
	if player:
		player.dialogue_active = true

# Start attacking once the intro dialogue is finished
func _on_intro_dialogue_finished() -> void:
	if player:
		player.dialogue_active = false
	dialogue_done = true
	attack_timer.start()

# Disable the dialogue once the death dialogue is finished
# Also allow the player to go to the next level
func _on_death_dialogue_finished(dialogue_box: Node) -> void:
	if is_instance_valid(dialogue_box):
		dialogue_box.queue_free()

	if player:
		player.dialogue_active = false
	
	# Enable the exit 
	var level_root := get_tree().current_scene.get_node("CurrentLevel").get_child(0)
	var exit := level_root.get_node_or_null("Exit")
	if exit and exit is Area2D:
		exit.visible = true
		exit.monitoring = true
		exit.set_deferred("monitorable", true)

		if not exit.level_completed.is_connected(get_node("/root/Game").next_level):
			exit.level_completed.connect(Callable(get_node("/root/Game"), "next_level"))

	queue_free()

# Flash red for taking damage
func flash_red():
	if has_node("Sprite2D"):
		var sprite := $Sprite2D
		sprite.modulate = Color(1, 0, 0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)
