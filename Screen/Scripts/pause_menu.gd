extends CanvasLayer

@onready var resume_button = $Pause/ResumeButton
@onready var restart_button = $Pause/RestartButton
@onready var menu_button = $Pause/MainMenuButton

func _ready():
	visible = false

	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_main_menu_pressed)

func open():
	visible = true
	get_tree().paused = true

func close():
	get_tree().paused = false
	visible = false

func _on_resume_pressed():
	close()

func _on_restart_pressed():
	close()
	get_node("/root/Game").load_level(get_node("/root/Game").current_level_index)

func _on_main_menu_pressed():
	close()
	get_tree().change_scene_to_file("res://Screen/title_screen.tscn")  # Adjust path if needed

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			print("close")
			close()
		else:
			open()
			print("open")
