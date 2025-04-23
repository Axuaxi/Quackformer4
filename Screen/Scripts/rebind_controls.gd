extends Button

@export var action_name: String
@export var default_key: String = ""

var waiting_for_key := false
static var active_rebind_button: Button = null

# 👇 Define your rebindable actions here (make sure it's shared across all buttons)
const REBINDABLE_ACTIONS := ["left", "right", "jump", "quack", "pause", "down"]

func _ready():
	set_process_unhandled_input(false)

	# Set default binding if none exists
	if InputMap.action_get_events(action_name).is_empty() and default_key != "":
		var keycode := OS.find_keycode_from_string(default_key)
		if keycode > 0:
			var event := InputEventKey.new()
			event.keycode = keycode
			event.physical_keycode = keycode
			InputMap.action_add_event(action_name, event)

	update_label()

func _pressed():
	if active_rebind_button != null:
		return

	text = "Press key..."
	waiting_for_key = true
	active_rebind_button = self
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not waiting_for_key or self != active_rebind_button:
		return

	if event is InputEventKey and event.pressed:
		var keycode: int = event.keycode
		var phys: int = event.physical_keycode


		if is_key_used_elsewhere(keycode, phys):
			text = "Already bound!"
			await get_tree().create_timer(1.0).timeout
		else:
			rebind_key(event)

		waiting_for_key = false
		active_rebind_button = null
		set_process_unhandled_input(false)
		update_label()

func rebind_key(new_event: InputEventKey) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, new_event)

func update_label() -> void:
	var keycode := get_current_keycode()
	text = OS.get_keycode_string(keycode if keycode != 0 else OS.find_keycode_from_string(default_key))

func get_current_keycode() -> int:
	for e in InputMap.action_get_events(action_name):
		if e is InputEventKey:
			return e.keycode
	return OS.find_keycode_from_string(default_key)

func is_key_used_elsewhere(keycode: int, phys_key: int) -> bool:
	for action in REBINDABLE_ACTIONS:
		if action == action_name:
			continue

		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey and (ev.keycode == keycode or ev.physical_keycode == phys_key):
				return true
	return false
