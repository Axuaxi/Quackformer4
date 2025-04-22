extends Area2D

@export var grav := 1200.0
var velocity := Vector2.ZERO

func initialize(initial_velocity: Vector2) -> void:
	velocity = initial_velocity

func _ready():
	add_to_group("eggs")  # 🥚 So it can be cleared globally

func _physics_process(delta: float) -> void:
	if Global.game_over:
		print("SIGMA")
		queue_free()
		return

	velocity.y += grav * delta
	position += velocity * delta

	# 🔄 Face the direction of movement
	rotation = velocity.angle() + deg_to_rad(-90)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.die_and_restart()
		queue_free()
	elif body is TileMapLayer:
		queue_free()
