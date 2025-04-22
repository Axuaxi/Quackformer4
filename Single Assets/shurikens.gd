extends Area2D

@export var start_speed := 0
@export var acceleration := 1000
@export var max_speed := 500
@export var lifetime := 3.0
@export var spin_speed := -5  # degrees per frame

var direction := Vector2.RIGHT
@onready var player = get_node_or_null("/root/Game/Player")

var speed := 0
var has_hit := false

func _ready():
	add_to_group("shurikens")
	$CollisionShape2D.disabled = false
	$GPUParticles2D.emitting = true
	has_hit = false

	# Lock in direction at spawn
	if is_instance_valid(player):
		direction = (player.global_position - global_position).normalized()

	# Rotate initial orientation to face direction (optional)
	rotation = direction.angle()

	if lifetime > 0:
		await get_tree().create_timer(lifetime).timeout
		_start_fade_and_die()

func _process(delta: float) -> void:
	# Move forward
	speed = min(speed + acceleration * delta, max_speed)
	position += direction.normalized() * speed * delta

	# Spin
	rotation += deg_to_rad(spin_speed)

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		if has_hit:
			return
		else:
			_start_fade_and_die()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and not has_hit:
		has_hit = true
		if body.has_method("take_damage"):
			body.killed_by_shuriken = true  # 👈 mark death cause
			body.take_damage(1)
		_start_fade_and_die()
	elif body is TileMapLayer:
		_start_fade_and_die()


func _start_fade_and_die():
	$GPUParticles2D.emitting = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.05)
	tween.tween_callback(self.queue_free)
