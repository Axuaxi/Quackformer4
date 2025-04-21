extends Area2D

@export var speed := 500
@export var drag := 300
var direction := Vector2.RIGHT

func _ready():
	$GPUParticles2D.emitting = true

func _process(delta: float) -> void:
	position += direction.normalized() * speed * delta

	# Apply drag
	speed = max(speed - drag * delta, 0)

	if speed == 0:
		# Stop trail & fade out
		$GPUParticles2D.emitting = false

		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(self.queue_free)

func _on_body_entered(body: Node) -> void:
	if body.name == "Boss" and body.has_method("take_damage"):
		body.take_damage(20)  # 👈 deal 20 damage
		queue_free()
	
	print("💥 Quack hit", body.name)
	queue_free()
	
