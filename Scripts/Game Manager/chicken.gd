# Script for the cow enemy and all of its params and behaviours

extends EnemyBase
class_name Chicken

@export var egg_scene: PackedScene
@export var shoot_interval: float = 1.5
@export var arc_height: float = 40.0
@export var gravity: float = 1200.0
@export var jump_strength: float = -300

@onready var player: CharacterBody2D = get_tree().get_root().get_node("Game/Player") as CharacterBody2D

var shoot_timer: float = 0.0

func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	set_physics_process(true)
	set_process(true)

	# Face player at spawn
	if player.global_position.x < global_position.x:
		scale.x = -abs(scale.x)
	else:
		scale.x = abs(scale.x)

	call_deferred("_finish_ready")


func _finish_ready() -> void:
	update_hp_bar()

func setup_with_stats(wave: int) -> void:
	if not is_inside_tree():
		await ready
	await get_tree().process_frame  # let _init_hp_safe() run

	# health first
	max_health = 1 if randi() % 2 == 0 else 2
	current_health = max_health

	# ensure the bar exists, then build+paint
	if hp_bar == null:
		_init_hp_safe()
	init_hp_bar()
	update_hp_bar()

	# randomize other stats
	shoot_interval *= randf_range(0.7, 2.5)
	arc_height *= randf_range(0.7, 1.3)
	gravity = ceil(gravity * randf_range(0.7, 1.3))
	
	
# Chicken process
func _process(delta: float) -> void:
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		shoot_egg_at_player()

# Try to jump if contact with the player (TODO: Fix this it dont work atm)
func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	# Check for jump if touching the player and on floor
	if is_on_floor():
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			var collider = col.get_collider()
			if collider != null and collider.name == "Player":
				velocity.y = jump_strength

	move_and_slide()

# Math to shoot the egg at the player (TODO: FIX THE MATH ITS SLIGHTLY OFF ATM)
func shoot_egg_at_player() -> void:
	if not is_instance_valid(player) or egg_scene == null:
		return

	var start: Vector2 = global_position
	var dx: float = player.global_position.x - start.x
	var vy: float = -sqrt(2.0 * gravity * arc_height)
	var time: float = abs(vy) / gravity * 2.0 * 2.0
	var vx: float = dx / time

	var egg: Area2D = egg_scene.instantiate()
	egg.global_position = start
	get_tree().current_scene.add_child(egg)

	if "initialize" in egg:
		egg.call("initialize", Vector2(vx, vy))
