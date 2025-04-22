extends CharacterBody2D

# --- CONFIG ---
@export var max_health := 10
@export var speed := 200
@export var gravity := 1000
@export var jump_strength := -300
@export var slam_interval := 2.0
@export var shuriken_scene: PackedScene
@export var max_slams := 2
@export var dialogue_box_scene: PackedScene = preload("res://Screen/UI/DialogueBox.tscn")

# --- NODES ---
@onready var player: Node2D = get_node("/root/Game/Player")
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var hp_bar: ProgressBar = $HPBar

# --- STATE ---
var is_slamming := false
var floored := false
var slam_count := 0
var current_health := max_health
var dialogue_done := false
var dead := false  # <--- NEW
var must_slam_next := false

# --- READY ---
func _ready() -> void:
	randomize()
	attack_timer.stop()
	attack_timer.wait_time = slam_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	hp_bar.max_value = max_health
	hp_bar.value = current_health
	show_intro_dialogue()

# --- PHYSICS ---
func _physics_process(delta: float) -> void:
	if dead:
		return  # Don't move or act if dead

	velocity.y += gravity * (0.4 if velocity.y < 0 else 3.0) * delta
	if not is_slamming:
		velocity.x = move_toward(velocity.x, 0, 1000 * delta)

	move_and_slide()

	if is_on_floor():
		if is_slamming and !floored:
			spawn_shockwave()
			is_slamming = false
		floored = true
		slam_count = 0
	else:
		floored = false

	if abs(velocity.x) > 5:
		sprite.scale.x = abs(sprite.scale.x) * sign(velocity.x)

# --- COMBAT ---
func _on_attack_timer_timeout() -> void:
	if dead or not dialogue_done:
		return
	if not is_instance_valid(player):
		return

	attack_timer.wait_time = randf_range(1.0, 3.0)
	attack_timer.start()

	if must_slam_next:
		print("⏭️ Forced SLAM after shuriken.")
		must_slam_next = false
		slam_toward_player_or_random()
		return

	if randf() < 0.65:
		print("💥 SLAM selected!")
		slam_toward_player_or_random()
	else:
		print("🌀 SHURIKEN selected!")
		throw_shuriken()
		must_slam_next = true  # 👈 Ensure next move is a slam

func slam_toward_player_or_random() -> void:
	if dead:
		return
	if slam_count >= max_slams:
		print("❌ Slam limit reached!")
		return

	is_slamming = true
	slam_count += 1
	floored = false

	var direction := Vector2.RIGHT
	if randf() < 0.5:
		direction = (player.global_position - global_position).normalized()
		print("💥 Jumping toward player!")
	else:
		direction = Vector2.LEFT if randi() % 2 == 0 else Vector2.RIGHT
		print("🎲 Random jump direction")

	velocity.x = direction.x * speed * randf_range(0.3, 1.0)
	velocity.y = jump_strength * 1.3

func throw_shuriken() -> void:
	if dead:
		return
	if not shuriken_scene:
		print("❌ No shuriken scene set!")
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

	# 🌪️ Screen shake!
	var cam := get_viewport().get_camera_2d()
	if cam and "shake" in cam:
		cam.shake(5)  # Adjust strength (e.g., 5–10)

	var shockwave_scene = preload("res://Single Assets/shockwave.tscn")
	for dir in [Vector2.LEFT, Vector2.RIGHT]:
		var shockwave = shockwave_scene.instantiate()
		shockwave.global_position = global_position + Vector2(0, -3)
		shockwave.direction = dir

		var sprite = shockwave.get_node_or_null("Sprite2D")
		if sprite:
			sprite.scale.x = -dir.x

		get_tree().current_scene.add_child(shockwave)


# --- DAMAGE / DEATH ---
func take_damage(amount: int) -> void:
	flash_red()
	if dead:
		return
	current_health -= amount
	hp_bar.value = current_health
	print("💢 Boss took", amount, "damage →", current_health, "HP")

	if current_health <= 0:
		die()

func die() -> void:
	if dead:
		return
	dead = true
	attack_timer.stop()
	print("👑 Boss defeated!")

	for node in get_tree().get_nodes_in_group("shurikens"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("shockwaves"):
		node.queue_free()

	# Make boss invisible and non-colliding
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

func _on_dialogue_finished(dialogue_box: Node) -> void:
	dialogue_box.queue_free()
	start_fight()
	if player:
		player.dialogue_active = false

func start_fight():
	dialogue_done = true
	attack_timer.start()

func _on_death_dialogue_finished(dialogue_box: Node) -> void:
	if is_instance_valid(dialogue_box):
		dialogue_box.queue_free()

	if player:
		player.dialogue_active = false

	# ✅ Enable Exit here instead
	var level_root := get_tree().current_scene.get_node("CurrentLevel").get_child(0)
	var exit := level_root.get_node_or_null("Exit")
	if exit and exit is Area2D:
		print("🚪 Enabling Exit!")
		exit.visible = true
		exit.monitoring = true
		exit.set_deferred("monitorable", true)

		if not exit.level_completed.is_connected(get_node("/root/Game").next_level):
			exit.level_completed.connect(Callable(get_node("/root/Game"), "next_level"))
	else:
		print("❌ Exit not found or not an Area2D!")

	queue_free()  # finally remove the boss

func _on_intro_dialogue_finished() -> void:
	if player:
		player.dialogue_active = false
	dialogue_done = true
	attack_timer.start()

func flash_red():
	if has_node("Sprite2D"):
		var sprite := $Sprite2D
		sprite.modulate = Color(1, 0, 0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)
