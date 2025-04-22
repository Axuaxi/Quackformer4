extends Panel

@onready var easy_btn = $EasyButton
@onready var medium_btn = $MediumButton
@onready var hard_btn = $HardButton
@onready var hardcore_btn = $HardcoreButton
@onready var description_label = $DescriptionLabel

func _ready():
	update_button_styles()
	easy_btn.mouse_entered.connect(_on_easy_hover)
	medium_btn.mouse_entered.connect(_on_medium_hover)
	hard_btn.mouse_entered.connect(_on_hard_hover)
	hardcore_btn.mouse_entered.connect(_on_hardcore_hover)

	# Optional: Clear when not hovering
	for btn in [easy_btn, medium_btn, hard_btn, hardcore_btn]:
		btn.mouse_exited.connect(_clear_description)
	
func update_button_styles():
	var selected_border = make_selected_border()

	# Clear all styles first
	for button in [easy_btn, medium_btn, hard_btn, hardcore_btn]:
		button.remove_theme_stylebox_override("normal")
		button.remove_theme_stylebox_override("hover")
		button.remove_theme_stylebox_override("pressed")

	# Apply white border to the selected difficulty
	match Global.difficulty:
		"easy":
			easy_btn.add_theme_stylebox_override("normal", selected_border)
		"medium":
			medium_btn.add_theme_stylebox_override("normal", selected_border)
		"hard":
			hard_btn.add_theme_stylebox_override("normal", selected_border)
		"hardcore":
			hardcore_btn.add_theme_stylebox_override("normal", selected_border)

func make_selected_border() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_border_width_all(2)
	box.border_color = Color.WHITE
	box.bg_color = Color.TRANSPARENT  # or any bg color you want
	return box
	
func _on_easy_hover():
	description_label.text = "Three feathers and all day to waste."

func _on_medium_hover():
	description_label.text = "Two feathers left. Better make 'em flap."

func _on_hard_hover():
	description_label.text = "One feather. One dream. No waddling back."

func _on_hardcore_hover():
	description_label.text = "The pond ain’t big enough for failures."

func _clear_description():
	description_label.text = ""
