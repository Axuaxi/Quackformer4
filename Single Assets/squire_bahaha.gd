extends CharacterBody2D

# --- CONFIG ---
@export var max_health := 1
@export var speed := 200
@export var gravity := 1000
@export var dialogue_box_scene: PackedScene = preload("res://Screen/UI/DialogueBox.tscn")
@export var hp_dot_texture: Texture2D
@export var hp_dot_empty_texture: Texture2D
@export var enemy_wave_scenes: Array[PackedScene]
@export var total_waves: int = 5
@export var cow_scene: PackedScene = preload("res://Single Assets/enemies/cow.tscn")
@export var chicken_scene: PackedScene = preload("res://Single Assets/enemies/chicken.tscn")



# --- NODES ---
@onready var player: Node2D = get_node("/root/Game/Player")
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var hp_bar: HBoxContainer = $HpContainer

# --- STATE ---
var current_health := max_health
var dialogue_done := false
var dead := false
var current_wave := 0
var spawning_wave := false
var active_enemies := []
var gravity_enabled := false
var has_landed := false


func _ready() -> void:
	randomize()
	add_to_group("bosses")
	connect("body_entered", Callable(self, "_on_body_entered"))
	hp_bar.add_theme_constant_override("separation", 1)
	attack_timer.stop()
	attack_timer.wait_time = 1.0
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	init_hp_bar()
	show_intro_dialogue()

func init_hp_bar() -> void:
	for child in hp_bar.get_children():
		child.queue_free()
	for i in max_health:
		var dot := TextureRect.new()
		dot.texture = hp_dot_texture
		dot.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		hp_bar.add_child(dot)

func _physics_process(delta: float) -> void:
	if dead:
		return

	if gravity_enabled:
		velocity.y += gravity * delta
	move_and_slide()

	if gravity_enabled and not has_landed and is_on_floor():
		has_landed = true
		_on_boss_landed()

func _on_boss_landed() -> void:
	print("💥 Boss landed! Triggering 'Ow!' dialogue.")
	if player:
		player.dialogue_active = true

	GlobalDialogue.dialogue_finished.connect(func():
		player.dialogue_active = false

		var label2 := get_parent().get_node_or_null("Label2")
		if label2:
			label2.visible = true
			label2.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(label2, "modulate:a", 1.0, 0.5)
	, CONNECT_ONE_SHOT)

	GlobalDialogue.start_dialogue(["Ow!"])

func _on_attack_timer_timeout() -> void:
	if dead or not dialogue_done or not is_instance_valid(player):
		return
	
	if current_wave > total_waves:
		print("✅ All waves complete!")
		gravity_enabled = true 
		return

	# Filter out any dead enemies
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e))

	print("📊 Checking wave", current_wave)
	print("🧟 Enemies remaining:", active_enemies.size())

	if active_enemies.size() == 0 and current_wave <= total_waves and not spawning_wave:
		current_wave += 1
		if current_wave > total_waves:
			print("✅ All waves complete!")
			return
		print("🚨 Spawning wave", current_wave)
		await spawn_enemy_wave()
		attack_timer.start()


func spawn_enemy_wave() -> void:
	var cow_count := 0
	var chicken_count := 0
	spawning_wave = true

	var count: int = clamp(current_wave + randi() % 3 - 1, 1, 100)
	for i in range(count):
		await get_tree().create_timer(0.4).timeout

		var is_chicken := randf() < 0.5
		var scene_to_use
		var enemy_type

		if is_chicken:
			scene_to_use = chicken_scene
			enemy_type = "Chicken"
			chicken_count += 1
		else:
			scene_to_use = cow_scene
			enemy_type = "Cow"
			cow_count += 1
		
		announce_wave(current_wave, cow_count, chicken_count)
		var enemy = scene_to_use.instantiate()
		enemy.name = "%s%d" % [enemy_type, i]

		var spawn_x: float
		if randf() < 0.5:
			spawn_x = randf_range(16, 116)
		else:
			spawn_x = randf_range(560, 640)

		enemy.global_position = Vector2(spawn_x, -300)
		get_tree().current_scene.add_child(enemy)

		if enemy.has_method("setup_with_stats"):
			enemy.call("setup_with_stats", current_wave)

		var area: Area2D = enemy.get_node_or_null("Area2D")
		if area and not area.is_connected("body_entered", Callable(enemy, "_on_body_entered")):
			area.connect("body_entered", Callable(enemy, "_on_body_entered"))

		active_enemies.append(enemy)
		print("✅ Spawned %s for Wave %d at %s" % [enemy.name, current_wave, str(enemy.global_position)])

	spawning_wave = false



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

func _on_body_entered(body: Node) -> void:
	if dead:
		return

	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(2)

	elif body.name == "Quack":
		print("🦆 Boss hit by Quack!")
		take_damage(1)
		

func die() -> void:
	if dead:
		return
	dead = true
	attack_timer.stop()

	# 🧹 Clear all enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

	visible = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0

	# ✅ Move Exit's CollisionShape2D to (40, -48)
	var level_root := get_tree().current_scene.get_node("CurrentLevel").get_child(0)
	var exit := level_root.get_node_or_null("Exit")
	if exit and exit is Area2D:
		var shape = exit.get_node_or_null("CollisionShape2D")
		if shape:
			shape.position = Vector2(40, -48)
			print("📍 Exit collision shape moved to (40, -48)")
		else:
			print("❌ CollisionShape2D not found in Exit")
	else:
		print("❌ Exit not found or not an Area2D!")

	# 🗨️ Dialogue box setup
	if not dialogue_box_scene:
		push_error("DialogueBox scene not assigned!")
		return
	
	var label2 := get_parent().get_node_or_null("Label2")
	var label3 := get_parent().get_node_or_null("Label3")

	if label2:
		var tween := create_tween()
		tween.tween_property(label2, "modulate:a", 0.0, 0.5)
		await tween.finished
		label2.visible = false

	if label3:
		label3.visible = true
		label3.modulate.a = 0.0
		var tween2 := create_tween()
		tween2.tween_property(label3, "modulate:a", 1.0, 0.5)
	
	var dialogue_box := dialogue_box_scene.instantiate()
	get_tree().current_scene.add_child(dialogue_box)

	if player:
		player.dialogue_active = true

	GlobalDialogue.dialogue_finished.connect(_on_death_dialogue_finished.bind(dialogue_box), CONNECT_ONE_SHOT)
	GlobalDialogue.start_dialogue([
		"What?!",
		"How?!",
		"My minions-"
	])


func show_intro_dialogue() -> void:
	GlobalDialogue.dialogue_finished.connect(_on_intro_dialogue_finished, CONNECT_ONE_SHOT)
	GlobalDialogue.start_dialogue([
		"You think you can take me on?",
		"Face my loyal minions first!",
		"Baaahhhahaha~"
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

func announce_wave(wave_num: int, num_cows: int, num_chickens: int) -> void:
	var parts = []

	if num_cows > 0:
		parts.append("%d Cow%s" % [num_cows, "s" if num_cows > 1 else ""])
	if num_chickens > 0:
		parts.append("%d Chicken%s" % [num_chickens, "s" if num_chickens > 1 else ""])

	var label_text = "Wave %d: %s" % [wave_num, " ".join(parts)]
	print(label_text)

	var label_node = get_parent().get_node_or_null("WaveLabel")
	if label_node:
		print("haslabel")
		var label = label_node
		
		label.text = label_text
		label.visible = true

		var tween = create_tween()
		label.modulate.a = 0.0
		tween.tween_property(label, "modulate:a", 1.0, 0.5)
		await tween.finished
		await get_tree().create_timer(5).timeout
		tween = create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 0.5)
		await tween.finished
		label.visible = false
