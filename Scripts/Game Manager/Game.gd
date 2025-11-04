# Main Script controlling the game

extends Node2D

@onready var player = $Player
@onready var current_level = $CurrentLevel
@onready var pause_menu = $PauseMenu
@onready var pause_toggle_button = $PauseToggleButto

# An array of all of the 30 levels in the game
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
	"res://Levels/Level11.tscn",
	"res://Levels/Level12.tscn",
	"res://Levels/Level13.tscn",
	"res://Levels/Level14.tscn",
	"res://Levels/Level15.tscn",
	"res://Levels/Level16.tscn",
	"res://Levels/Level17.tscn",
	"res://Levels/Level18.tscn", # Boss level
	"res://Levels/Level19.tscn",
	#"res://Levels/Level20.tscn", # TODO: 30 LEVELS PLANNED FOR THE GAME, CURRENTLY ONLY 18 OF THEM ARE COMPLETED AND THE 19TH IS JUSt A FILLER LEVEL
	#"res://Levels/Level21.tscn",
	#"res://Levels/Level22.tscn",
	#"res://Levels/Level23.tscn",
	#"res://Levels/Level24.tscn",
	#"res://Levels/Level25.tscn",
	#"res://Levels/Level26.tscn",
	#"res://Levels/Level27.tscn",
	#"res://Levels/Level28.tscn",
	#"res://Levels/Level29.tscn",
	#"res://Levels/Level30.tscn",
]

# Index of the current level 
var current_level_index = 0

# Block triggers initially
var allow_trigger := false

# Blocks reloading the level initially 
var is_reloading := false

# Sets the killed by shuriken/shockwave to be false initially (TODO: CHANGE THIS TO NOT BE IN THE ENTIRE GAME, AND JUST LEVEL 8)
var killed_by_shuriken: bool = false
var killed_by_shockwave: bool = false

# Starts the level (index 0)
func _ready() -> void:
	load_level(current_level_index)
	Global.difficulty

# Function to lead the indexed level
func load_level(index: int) -> void:
	# Stops multiple reloadings
	if is_reloading:
		return 
		
	# Resets the game_over state incase the player died to something instead of completing the prev level
	Global.game_over = false
	
	# Resets all player stats
	player.current_health =player.max_health
	player.update_hp_bar()
	is_reloading = true
	allow_trigger = false

	# Remove all shurikens (TODO: CHANGE THIS TO NOT BE IN THE ENTIRE GAME AND JUST BOSS LEVEL)
	for shuriken in get_tree().get_nodes_in_group("shurikens"):
		shuriken.queue_free()
	for shuriken in get_tree().get_nodes_in_group("shockwaves"):
		shuriken.queue_free()
	for shuriken in get_tree().get_nodes_in_group("eggs"):
		shuriken.queue_free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for quack in get_tree().get_nodes_in_group("quacks"):
		quack.queue_free()
	
	_clear_current_level()

	var new_level = _load_new_level(index)
	current_level.add_child(new_level)

	# Set up all the triggers
	_setup_exit_trigger(new_level)
	_setup_player_start(new_level)
	_setup_enemy_trigger(new_level)
	
	# If the autoscrolling level, then set up the lava and camera
	if index == 5:
		_setup_lava_and_camera(new_level)

	# Lava setup
	var lava_map = new_level.get_node_or_null("LavaMap")
	if lava_map and not lava_map.is_connected("lava_touch", Callable(player, "_on_lava_touch")):
		lava_map.connect("lava_touch", Callable(player, "_on_lava_touch"))

	# If the quack pickup level, set up the quack interactable
	if index == 4:
		var pickup = new_level.get_node_or_null("QuackPickup/Area2D")
		if pickup and not pickup.is_connected("quack_unlocked", Callable(player, "_on_quack_unlocked")):
			pickup.connect("quack_unlocked", Callable(player, "_on_quack_unlocked"))
	
	# Debug statement
	print("Loaded level:", index)

	await get_tree().create_timer(0.4).timeout
	allow_trigger = true
	is_reloading = false


# --- Helpers ---

# Clears the current level (All entities removed from the level)
func _clear_current_level() -> void:
	if current_level.get_child_count() > 0:
		current_level.get_child(0).queue_free()

# Loads the new level
func _load_new_level(index: int) -> Node:
	return load(level_paths[index]).instantiate()

# Setup the player's starting position
func _setup_player_start(level: Node) -> void:
	var start = level.get_node_or_null("StartPosition")
	if start:
		player.global_position = start.global_position
	else:
		# Default backup starting position incase I forget to add the starting position ih a level LMAO
		print("No starting pos found - using default")
		player.global_position = Vector2.ZERO

# Setup the exit trigger of the level
func _setup_exit_trigger(level: Node) -> void:
	# If its not the boss level
	if current_level_index != 7:
		var exit = level.get_node_or_null("Exit")
		if exit and exit is Area2D:
			exit.monitoring = false
			await get_tree().process_frame
			exit.monitoring = true

			if not exit.level_completed.is_connected(Callable(self, "next_level")):
				exit.level_completed.connect(Callable(self, "next_level"))
				
	# If it is the boss level then get rid of it til its over (perchance)
	else:
		var exit = level.get_node_or_null("Exit")
		if exit and exit is Area2D:
			exit.visible = false
			exit.monitoring = false  # Disable detection

			# Prevent preemptive triggering
			if exit.level_completed.is_connected(Callable(self, "next_level")):
				exit.level_completed.disconnect(Callable(self, "next_level"))

# Setup the enemy triggers
func _setup_enemy_trigger(level: Node) -> void:
	# Get the area nodes
	var area_nodes = level.find_children("*", "Area2D", true, false)
	for area in area_nodes:
		if area.collision_layer & (1 << 2):  # Layer 3
			if not area.is_connected("body_entered", Callable(self, "_on_enemy_touch")):
				area.connect("body_entered", Callable(self, "_on_enemy_touch").bind(area))

# Setup the lava and camera in the autoscroll level
func _setup_lava_and_camera(level: Node) -> void:
	var lava_area = level.get_node_or_null("Lava/Area2D")
	var camera = level.get_node_or_null("ScrollingCamera")

	if lava_area and camera:
		lava_area.player = player
		lava_area.camera = camera
		camera.make_current()

# --- Triggers ---

# Advancing the level index to the next level
func next_level() -> void:
	if not allow_trigger:
		return
	
	# Preventing re entry here
	allow_trigger = false 

	# Debug statement here
	print("Next level")
	current_level_index += 1

	# If theres a next level to go to then load it
	if current_level_index < level_paths.size():
		load_level(current_level_index)
	# Otherwise the game is done
	else:
		print("GG game finished")

	# Reset trigger after short delay to prevent skipping multiple levels
	await get_tree().create_timer(0.5).timeout
	allow_trigger = true

# Clears the duck dying to shuriken/shockwave in Boss level 8 (TODO: REMOVE THIS FROM THE ENTIRE GAME AND MAKE IT ITS OWN THING)
func clear_death_flags() -> void:
	killed_by_shuriken = false
	killed_by_shockwave = false

# If the player touches an enemy then take damage
func _on_enemy_touch(body: Node, area: Area2D) -> void:
	# In case something goes wrong, then do nothing
	if body.name != "Player" or not body.has_method("take_damage"):
		return

	# Assume Area2D is direct child of Cow
	var enemy := area.get_parent() 

	# Bosses do double damage
	if enemy.is_in_group("bosses"):
		body.take_damage(2)
		# Specifically for the pig boss, if the boss touches the player then it does its jump attack again
		if enemy.has_method("slam_toward_player_or_random"):
			enemy.slam_toward_player_or_random()
	# Enemies do 1 damage
	elif enemy.is_in_group("enemies"):
		body.take_damage(1)
		
# Get the current calling area 
func get_current_calling_area() -> Area2D:
	var stack = get_stack()
	for entry in stack:
		if entry.source.ends_with(".gd") and entry.function == "_on_enemy_touch":
			var area_node = get_node_or_null(entry.source)
			if area_node and area_node is Area2D:
				return area_node
	return null

# Processes specifically for the sky level here 
func _physics_process(delta: float) -> void:
	if player and player.global_position.y > 80 and not Global.game_over:
		player.take_damage(player.max_health)
		
# Skip button for dev to skip level for testing
func _handle_skip(input: InputEvent) -> void:
	if input.is_action_pressed("skip level"):
		next_level()
		
# Restart button incase duck gets stuck or smth
func _handle_restart(input: InputEvent) -> void:
	if input.is_action_pressed("restart level"):
		load_level(current_level_index)
		
# Back button for dev to go back a level for testing
func _handle_prev(input: InputEvent) -> void:
	if input.is_action_pressed("prev level"):
		current_level_index -= 1
		load_level(current_level_index)
	
# Handles the 3 inputs 
func _unhandled_input(event: InputEvent) -> void:
	_handle_skip(event)
	_handle_prev(event)
	_handle_restart(event)
	
	
