extends OptionsBar
@export var scene_to_open: PackedScene
@onready var root: = $"../../../../"

func _unhandled_key_input(_e: InputEvent) -> void:
	if scene_to_open == null: return

	if selected:
		if root.has_node("option_scene"): return
		root.process_mode = Node.PROCESS_MODE_DISABLED

		var option_scene: = scene_to_open.instantiate()
		option_scene.process_mode = Node.PROCESS_MODE_ALWAYS
		option_scene.name = "option_scene"
		option_scene.exit_callback = func() -> void:
			root.process_mode = Node.PROCESS_MODE_ALWAYS
			selected = false
		root.add_child(option_scene)
	else:
		if root.has_node("option_scene"):
			root.remove_child(root.get_node("option_scene"))
