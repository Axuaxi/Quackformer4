# Script controlling the egg enemy egg rpojectile

extends Area2D

@export var grav := 620
var velocity := Vector2.ZERO

# Initializes the egg
func initialize(initial_velocity: Vector2) -> void:
	velocity = initial_velocity

# Adds to eggs group on ready so it can be cleared globally
func _ready():
	add_to_group("eggs")

# Always calculates the position/velocity and rotates the sprite accordingly
func _physics_process(delta: float) -> void:
	if Global.game_over:
		queue_free()
		return

	velocity.y += grav * delta
	position += velocity * delta

	# Rotates the sprite according to the velocity angle 
	rotation = velocity.angle() + deg_to_rad(-90)

# Damage the player on collision with player, and delete itself no matter what kind of collision it was
func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.take_damage(1)
		queue_free()
	elif body is TileMapLayer:
		queue_free()
