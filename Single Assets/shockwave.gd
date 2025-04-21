extends Area2D

@export var start_speed := 0
@export var acceleration := 500
@export var max_speed := 2000
var direction := Vector2.RIGHT
var speed := 0.0

func _ready() -> void:
	add_to_group("shockwaves")
	$CollisionPolygon2D.disabled = false
	$GPUParticles2D.emitting = true

	var boss = get_boss()
	if boss and boss.dead:
		queue_free()
		return

	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1)

func _process(delta: float) -> void:
	speed = min(speed + acceleration * delta, max_speed)
	position += direction.normalized() * speed * delta

func _on_body_entered(body: Node) -> void:
	var boss = get_boss()
	if boss and boss.dead:
		queue_free()
		return

	if body.name == "Player":
		if body.has_method("die_with_boss_dialogue"):
			if boss:
				boss.dialogue_done = false
			await body.die_with_boss_dialogue(["Fool."] as Array[String])
			if boss:
				boss.dialogue_done = true
		else:
			body.die_and_restart()

func _start_fade_and_die():
	$GPUParticles2D.emitting = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.05)
	tween.tween_callback(self.queue_free)

func get_boss():
	var level_root := get_node_or_null("/root/Game/CurrentLevel")
	return level_root.get_child(0).get_node_or_null("Boss") if level_root else null
