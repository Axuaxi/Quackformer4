extends EnemyBase
class_name Chicken

@export var egg_scene: PackedScene
@export var shoot_interval: float = 1.5
@export var arc_height: float = 40.0
@export var scale_direction: int = 1
@export var gravity: float = 1200.0

@onready var player: CharacterBody2D = get_tree().get_root().get_node("Game/Player") as CharacterBody2D

var shoot_timer: float = 0.0

func _ready() -> void:
	super._ready()  # ✅ This calls EnemyBase._ready()

	scale.x *= scale_direction
	add_to_group("enemies")
	set_process(true)
	set_physics_process(true)

	call_deferred("_finish_ready")


func _finish_ready() -> void:
	if not hp_bar:
		print("❌ HpContainer still missing in Chicken")
	else:
		update_hp_bar()

func setup_with_stats(wave: int) -> void:
	max_health = 1 if randi() % 2 == 0 else 2
	current_health = max_health
	shoot_interval = floor(shoot_interval * randf_range(0.7, 1.3))
	arc_height = arc_height * randf_range(0.7, 1.3)
	gravity = ceil(gravity * randf_range(0.7, 1.3))

	print("🐔 Chicken setup complete for wave %d: interval=%.2f, arc=%.2f, gravity=%.1f" % [wave, shoot_interval, arc_height, gravity])

	call_deferred("update_hp_bar")  # wait until hp_bar is guaranteed assigned

func _process(delta: float) -> void:
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		shoot_egg_at_player()

	# Flip chicken to face the player
	if player.global_position.x < global_position.x:
		scale.x = -abs(scale.x)  # Face left
	else:
		scale.x = abs(scale.x)   # Face right

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
