extends EnemyBase
class_name Chicken

@export var egg_scene: PackedScene
@export var shoot_interval: float = 1.5
@export var arc_height: float = 40.0
@export var scale_direction: int = 1
@export var gravity: float = 1200.0  # ✅ Gravity value

@onready var player: CharacterBody2D = get_tree().get_root().get_node("Game/Player") as CharacterBody2D

var shoot_timer: float = 0.0

func _ready() -> void:
	scale.x *= scale_direction
	add_to_group("enemies")
	set_process(true)
	set_physics_process(true)

func setup_with_stats(wave: int) -> void:
	# 🧪 Randomize and round stats ±30%
	shoot_interval = ceil(shoot_interval * randf_range(0.7, 1.3))
	arc_height = ceil(arc_height * randf_range(0.7, 1.3))
	gravity = ceil(gravity * randf_range(0.7, 1.3))

	# Optional: randomize health
	max_health += wave - 1
	max_health = ceil(max_health * randf_range(0.7, 1.3))
	current_health = max_health
	init_hp_bar()
	update_hp_bar()

	print("🐔 Chicken setup complete for wave %d: interval=%.2f, arc=%.2f, gravity=%.1f" %
		[wave, shoot_interval, arc_height, gravity])


func _process(delta: float) -> void:
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		shoot_egg_at_player()

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	move_and_slide()

func shoot_egg_at_player() -> void:
	if not is_instance_valid(player) or egg_scene == null:
		return

	var start: Vector2 = global_position
	var target_x: float = player.global_position.x 

	var dx: float = target_x - start.x
	var arc: float = arc_height
	var vy: float = -sqrt(2.0 * gravity * arc)

	var time: float = abs(vy) / gravity * 2.0 * 2.0 
	var vx: float = dx / time 

	var egg: Area2D = egg_scene.instantiate() as Area2D
	egg.global_position = start
	get_tree().current_scene.add_child(egg)

	if "initialize" in egg:
		egg.call("initialize", Vector2(vx, vy))


func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		queue_free()
