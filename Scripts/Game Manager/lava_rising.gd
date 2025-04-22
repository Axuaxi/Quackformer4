extends Area2D

@export var max_rise_speed := 50.0
@export var start_rise_speed := 45.0
@export var max_shake_intensity := 8.0
@export var camera: Camera2D
@export var player: Node
@export var stop_y := -1145.0

var scrolling := false
var started := false

var current_rise_speed := 0.0
var current_shake_intensity := 0.0

@onready var lava_shader_material: ShaderMaterial = $Sprite2D.material

func start_rising() -> void:
	if not started:
		started = true
		current_rise_speed = start_rise_speed  # start at 40
		#await get_tree().create_timer(1.0).timeout
		scrolling = true
		print("🔥 Lava rising started!")

func _process(delta: float) -> void:
	if lava_shader_material and lava_shader_material is ShaderMaterial:
		lava_shader_material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)

	if scrolling:
		# Stop if we've reached the stop height
		if position.y <= stop_y:
			print("🛑 Lava reached stop height")
			scrolling = false
			if camera:
				camera.offset = Vector2.ZERO
			return

		# Gradually increase rise speed and shake intensity
		current_rise_speed = min(current_rise_speed + 2.0 * delta, max_rise_speed)
		current_shake_intensity = min(current_shake_intensity + 0.1 * delta, max_shake_intensity)

		position.y -= current_rise_speed * delta

		# Shake camera
		if camera:
			var offset = Vector2(
				randf_range(-current_shake_intensity, current_shake_intensity),
				randf_range(-current_shake_intensity, current_shake_intensity)
			)
			camera.offset = offset
	else:
		if camera:
			camera.offset = Vector2.ZERO

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		print("🔥 Lava touched player!")
		if Global.difficulty != "hardcore":
			get_node("/root/Game").load_level(get_node("/root/Game").current_level_index)
		else:
			get_node("/root/Game").current_level_index = 0
			body.can_quack = false
			body.hp_bar.visible = false
			get_node("/root/Game").load_level(0)  
