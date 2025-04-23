extends EnemyBase

@export var egg_scene: PackedScene
@export var shoot_interval: float = 1.5
@export var arc_height: float = 40.0

@onready var player: CharacterBody2D = get_tree().get_root().get_node("Game/Player") as CharacterBody2D

var shoot_timer: float = 0.0

func _process(delta: float) -> void:
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		shoot_egg_at_player()

func shoot_egg_at_player() -> void:
	if not is_instance_valid(player) or egg_scene == null:
		return

	var start: Vector2 = global_position
	var target_x: float = player.global_position.x 

	var dx: float = target_x - start.x
	var gravity: float = 1200.0
	var arc: float = arc_height
	var vy: float = -sqrt(2.0 * gravity * arc)
	var time: float = abs(vy) / gravity * 2.0
	var vx: float = dx / time 

	vx *= 0.8  

	var egg: Area2D = egg_scene.instantiate() as Area2D
	egg.global_position = start
	get_tree().current_scene.add_child(egg)

	if "initialize" in egg:
		egg.call("initialize", Vector2(vx, vy))



func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		queue_free()
