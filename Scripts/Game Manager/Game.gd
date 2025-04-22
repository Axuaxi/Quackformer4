extends Node2D

@onready var player = $Player
@onready var current_level = $CurrentLevel
@onready var pause_menu = $PauseMenu
@onready var pause_toggle_button = $PauseToggleButto

var level_paths = [
	"res://Levels/Level1.tscn",
	"res://Levels/Level2.tscn",
	"res://Levels/Level3.tscn",
	"res://Levels/Level4.tscn",
	"res://Levels/Level5.tscn",
	"res://Levels/Level6.tscn",
	"res://Levels/Level7.tscn",
	"res://Levels/Level8.tscn",  # Boss level
	"res://Levels/Level9.tscn",
	"res://Levels/Level10.tscn",
	"res://Levels/Level11.tscn"
]

var current_level_index = 0
var allow_trigger := false  # 🔒 Block triggers initially
var is_reloading := false
var killed_by_shuriken: bool = false
var killed_by_shockwave: bool = false

func _ready() -> void:
	load_level(current_level_index)
	Global.difficulty

func load_level(index: int) -> void:
	if is_reloading:
		return  # 🚫 Prevent multiple reloads
		
	Global.game_over = false
	
	player.current_health =player.max_health
	player.update_hp_bar()
	is_reloading = true
	allow_trigger = false

	# 💥 Remove all shurikens
	for shuriken in get_tree().get_nodes_in_group("shurikens"):
		shuriken.queue_free()
	for shuriken in get_tree().get_nodes_in_group("shockwaves"):
		shuriken.queue_free()
	for shuriken in get_tree().get_nodes_in_group("eggs"):
		shuriken.queue_free()
	
	_clear_current_level()

	var new_level = _load_new_level(index)
	current_level.add_child(new_level)

	_setup_player_start(new_level)
	_setup_exit_trigger(new_level)
	_setup_enemy_trigger(new_level)

	if index == 5:
		_setup_lava_and_camera(new_level)

	var lava_map = new_level.get_node_or_null("LavaMap")
	if lava_map and not lava_map.is_connected("lava_touch", Callable(player, "_on_lava_touch")):
		lava_map.connect("lava_touch", Callable(player, "_on_lava_touch"))

	if index == 4:
		var pickup = new_level.get_node_or_null("QuackPickup/Area2D")
		if pickup and not pickup.is_connected("quack_unlocked", Callable(player, "_on_quack_unlocked")):
			pickup.connect("quack_unlocked", Callable(player, "_on_quack_unlocked"))

	print("📦 Loaded Level", index)

	await get_tree().create_timer(0.4).timeout
	allow_trigger = true
	is_reloading = false


# --- Helpers ---

func _clear_current_level() -> void:
	if current_level.get_child_count() > 0:
		current_level.get_child(0).queue_free()

func _load_new_level(index: int) -> Node:
	return load(level_paths[index]).instantiate()

func _setup_player_start(level: Node) -> void:
	var start = level.get_node_or_null("StartPosition")
	if start:
		player.global_position = start.global_position
		print("✅ Player moved to StartPosition at:", start.global_position)
	else:
		print("❌ StartPosition not found! Using fallback (0, 0).")
		player.global_position = Vector2.ZERO

func _setup_exit_trigger(level: Node) -> void:
	if current_level_index != 7:
		var exit = level.get_node_or_null("Exit")
		if exit and exit is Area2D:
			exit.monitoring = false
			await get_tree().process_frame
			exit.monitoring = true

			if not exit.level_completed.is_connected(Callable(self, "next_level")):
				exit.level_completed.connect(Callable(self, "next_level"))
				
	else:
		var exit = level.get_node_or_null("Exit")
		if exit and exit is Area2D:
			exit.visible = false
			exit.monitoring = false  # Disable detection

			# Prevent preemptive triggering
			if exit.level_completed.is_connected(Callable(self, "next_level")):
				exit.level_completed.disconnect(Callable(self, "next_level"))

func _setup_enemy_trigger(level: Node) -> void:
	var area_nodes = level.find_children("*", "Area2D", true, false)
	for area in area_nodes:
		if area.collision_layer & (1 << 2):  # Layer 3
			if not area.is_connected("body_entered", Callable(self, "_on_enemy_touch")):
				area.connect("body_entered", Callable(self, "_on_enemy_touch").bind(area))

func _setup_lava_and_camera(level: Node) -> void:
	var lava_area = level.get_node_or_null("Lava/Area2D")
	var camera = level.get_node_or_null("ScrollingCamera")

	if lava_area and camera:
		lava_area.player = player
		lava_area.camera = camera
		camera.make_current()

# --- Triggers ---

func next_level() -> void:
	if not allow_trigger:
		return

	allow_trigger = false  # Prevent re-entry

	print("⏭️ Advancing to next level")
	current_level_index += 1

	if current_level_index < level_paths.size():
		load_level(current_level_index)
	else:
		print("🏁 Game Finished")

	# Reset trigger after short delay to prevent skipping multiple levels
	await get_tree().create_timer(0.5).timeout
	allow_trigger = true

func clear_death_flags() -> void:
	killed_by_shuriken = false
	killed_by_shockwave = false

func _on_enemy_touch(body: Node, area: Area2D) -> void:
	if body.name != "Player" or not body.has_method("take_damage"):
		return

	var enemy := area.get_parent().get_parent()  # FloorHitbox → Hitbox → Boss

	if enemy.is_in_group("bosses"):
		body.take_damage(2)
		if enemy.has_method("slam_toward_player_or_random"):
			enemy.slam_toward_player_or_random()
	else:
		body.take_damage(1)

func get_current_calling_area() -> Area2D:
	var stack = get_stack()
	for entry in stack:
		if entry.source.ends_with(".gd") and entry.function == "_on_enemy_touch":
			var area_node = get_node_or_null(entry.source)
			if area_node and area_node is Area2D:
				return area_node
	return null


func _physics_process(delta: float) -> void:
	if player and player.global_position.y > 80 and not Global.game_over:
		print("☠️ Player fell off! Damaging...")
		player.take_damage(player.max_health)

func _handle_skip(input: InputEvent) -> void:
	if input.is_action_pressed("skip level"):
		print("⏭️ Skipping to next level")
		next_level()
		
func _handle_prev(input: InputEvent) -> void:
	if input.is_action_pressed("prev level"):
		current_level_index -= 1
		load_level(current_level_index)
	
func _unhandled_input(event: InputEvent) -> void:
	_handle_skip(event)
	_handle_prev(event)
