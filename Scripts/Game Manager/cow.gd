extends CharacterBody2D

@export var speed := 100
@export var acceleration := 300
@export var friction := 300	
@export var gravity := 1000
@export var jump_strength := -320

@onready var player = get_node("/root/Game/Player")
@onready var sprite = $Sprite2D  

func _process(delta: float) -> void:
	if player == null:
		return
	
	var target_x = player.global_position.x
	var direction = sign(target_x - global_position.x)
	var target_speed = direction * speed
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	position.x += velocity.x * delta
	velocity.y += gravity * delta
	
	if is_on_floor() and velocity.y > 0:
		velocity.y = 0

	# 🐄 Flip sprite to face direction of movement
	if velocity.x != 0:
		sprite.scale.x = sign(velocity.x)

	move_and_slide()
	
	# Wall bounce
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if abs(collision.get_normal().x) > 0.8:
			if is_on_floor():
				print("Cow hit wall — jumping!")
				velocity.y = jump_strength
