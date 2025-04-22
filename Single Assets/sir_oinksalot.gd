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
		if is_slamming:
			spawn_shockwave()
			velocity.x = 0
			is_slamming = false 
			
			# ✅ Only allow chained slam if on floor (again)
			if randf() < 0.5:
				print("🔁 Chained slam triggered!")
				await get_tree().create_timer(0.1).timeout
				if is_on_floor():  # 🔒 Guard again before chaining
					slam_toward_player_or_random()

		floored = true

	if abs(velocity.x) > 5:
		sprite.scale.x = abs(sprite.scale.x) * sign(velocity.x)

	# 👇 Auto slam if on floor, above threshold, and player is invincible
	if is_on_floor() and global_position.y < -38.0:
		if "is_invincible" in player and player.is_invincible and not is_slamming:
			print("🔥 Auto-slam triggered by invincibility height condition!")
			slam_toward_player_or_random()

# --- COMBAT ---
func _on_attack_timer_timeout() -> void:
	if dead or not dialogue_done or not is_instance_valid(player):
		return

	if must_slam_next:
		must_slam_next = false
		await slam_and_wait()
	else:
		if randf() < 0.5:
			await slam_and_wait()
		else:
			throw_shuriken()
			must_slam_next = true
			attack_timer.wait_time = randf_range(2.0, 4.0)
			attack_timer.start()

func slam_and_wait() -> void:
	slam_toward_player_or_random()
	while is_slamming:
		await get_tree().process_frame
	attack_timer.wait_time = randf_range(1.0, 3.0)
	attack_timer.start()


func slam_toward_player_or_random() -> void:
	if dead or is_slamming:
		return

	is_slamming = true
	floored = false

	var direction := Vector2.RIGHT
	if randf() < 0.5:
		direction = (player.global_position - global_position).normalized()
	else:
		direction = Vector2.LEFT if randi() % 2 == 0 else Vector2.RIGHT

	velocity.x = direction.x * speed * randf_range(0.3, 1.0)
	velocity.y = jump_strength * 1.3

func throw_shuriken() -> void:
	if dead or not shuriken_scene:
		return

	var shuriken_count := randi() % 3 + 1
	fire_shurikens_sequentially(shuriken_count)

func fire_shurikens_sequentially(count: int) -> void:
	if dead:
		return
	var aim_dir := (player.global_position - global_position).normalized()
	if aim_dir.x != 0:
		sprite.scale.x = abs(sprite.scale.x) * sign(aim_dir.x)

	for i in count:
		await get_tree().create_timer(0.15).timeout
		var shuriken = shuriken_scene.instantiate()
		shuriken.global_position = global_position
		shuriken.direction = aim_dir
		get_tree().current_scene.add_child(shuriken)

func spawn_shockwave() -> void:
	if dead:
		return

	var cam := get_viewport().get_camera_2d()
	if cam and "shake" in cam:
		cam.shake(5)

	var shockwave_scene = preload("res://Single Assets/shockwave.tscn")
	for dir in [Vector2.LEFT, Vector2.RIGHT]:
		var shockwave = shockwave_scene.instantiate()
		shockwave.global_position = global_position + Vector2(0, -3)
		shockwave.direction = dir

		var sprite = shockwave.get_node_or_null("Sprite2D")
		if sprite:
			sprite.scale.x = -dir.x

		get_tree().current_scene.add_child(shockwave)

# --- DAMAGE ---
func take_damage(amount: int) -> void:
	flash_red()
	if dead:
		return
	current_health -= amount
	update_hp_bar()
	if current_health <= 0:
		die()

func update_hp_bar() -> void:
	for i in hp_bar.get_child_count():
		var dot = hp_bar.get_child(i) as TextureRect
		dot.texture = hp_dot_texture if i < current_health else hp_dot_empty_texture

# --- CONTACT DAMAGE ---
func _on_body_entered(body: Node) -> void:
	print("CONTACT BOSS DUCK")
	if dead:
		return

	if body.name == "Player" and body.has_method("take_damage"):
		print("🐷 Boss touched player!")

		# If player is invincible, slam instead (if on floor)
		if "is_invincible" in body and body.is_invincible:
			if is_on_floor() and not is_slamming:
				print("⚠️ Player invincible — boss slams instead!")
				slam_toward_player_or_random()
			else:
				print("⚠️ Player invincible, but boss not on floor")
		else:
			body.take_damage(2)
			if not is_slamming:
				slam_toward_player_or_random()

# --- DEATH ---
func die() -> void:
	if dead:
		return
	dead = true
	attack_timer.stop()

	for node in get_tree().get_nodes_in_group("shurikens"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("shockwaves"):
		node.queue_free()

	visible = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0

	if not dialogue_box_scene:
		push_error("DialogueBox scene not assigned!")
		return

	var dialogue_box := dialogue_box_scene.instantiate()
	get_tree().current_scene.add_child(dialogue_box)

	if player:
		player.dialogue_active = true

	GlobalDialogue.dialogue_finished.connect(_on_death_dialogue_finished.bind(dialogue_box), CONNECT_ONE_SHOT)
	GlobalDialogue.start_dialogue([
		"You-",
		"You-",
		"..."
	])

# --- DIALOGUE ---
func show_intro_dialogue() -> void:
	GlobalDialogue.dialogue_finished.connect(_on_intro_dialogue_finished, CONNECT_ONE_SHOT)
	GlobalDialogue.start_dialogue([
		"You've made it this far... but you won't leave alive.",
		"I, Sir Oinksalot will personally see to your demise.",
		"Prepare yourself, DUCK!"
	])
	if player:
		player.dialogue_active = true

func _on_intro_dialogue_finished() -> void:
	if player:
		player.dialogue_active = false
	dialogue_done = true
	attack_timer.start()

func _on_death_dialogue_finished(dialogue_box: Node) -> void:
	if is_instance_valid(dialogue_box):
		dialogue_box.queue_free()

	if player:
		player.dialogue_active = false

	var level_root := get_tree().current_scene.get_node("CurrentLevel").get_child(0)
	var exit := level_root.get_node_or_null("Exit")
	if exit and exit is Area2D:
		exit.visible = true
		exit.monitoring = true
		exit.set_deferred("monitorable", true)

		if not exit.level_completed.is_connected(get_node("/root/Game").next_level):
			exit.level_completed.connect(Callable(get_node("/root/Game"), "next_level"))
	else:
		print("❌ Exit not found or not an Area2D!")

	queue_free()

func flash_red():
	if has_node("Sprite2D"):
		var sprite := $Sprite2D
		sprite.modulate = Color(1, 0, 0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)
