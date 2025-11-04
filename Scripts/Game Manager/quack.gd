# Script controlling the quack projectile

extends Area2D

# How fast the projectile is
@export var speed := 650
# How fast the projectile slows down
@export var drag := 507
# Default dir of the projectile
var direction := Vector2.RIGHT

# On ready, add to "quacks" and start playing its trail animation shader
func _ready():
	add_to_group("quacks")  
	$GPUParticles2D.emitting = true

# Processes the quack projectile
func _process(delta: float) -> void:
	# The math of the speed of the quack
	position += direction.normalized() * speed * delta

	# Apply drag
	speed = max(speed - drag * delta, 0)
	
	# Once its fully stopped, then delete the projectile
	if speed == 0:
		# Stop trail & fade out
		$GPUParticles2D.emitting = false

		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(self.queue_free)

# Controls the damage of the quack 
func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1) 
		queue_free()
	# Does nothing if its underwater
	if body.name == "WaterTileMap":
		return 
	
	queue_free()
	
