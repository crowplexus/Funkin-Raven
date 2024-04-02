extends OptionsBar
@onready var kbs_window: PackedScene = load("res://raven/game/ui/options/keybinds_window.tscn")
@onready var root: = $"../../../../"

func _unhandled_key_input(_e: InputEvent):
	if selected:
		if root.has_node("keybinds_window"): return
		root.process_mode = Node.PROCESS_MODE_DISABLED
		
		var keybinds_window: = kbs_window.instantiate()
		keybinds_window.process_mode = Node.PROCESS_MODE_ALWAYS
		keybinds_window.on_leave = func():
			root.process_mode = Node.PROCESS_MODE_ALWAYS
			selected = false
		keybinds_window.name = "keybinds_window"
		root.add_child(keybinds_window)
	else:
		if root.has_node("keybinds_window"):
			root.remove_child(root.get_node("keybinds_window"))
