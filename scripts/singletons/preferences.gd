extends Node

@export_group("Gameplay Options")
## Self-explanatory.
@export var keybinds: Dictionary = {
	"note0": [	"S",	"Left"	],
	"note1": [	"D",	"Down"	],
	"note2": [	"K",	"Up"	],
	"note3": [	"L",	"Right"	],
}
## Defines which direction the notes will scroll to.
@export_enum("Up:0", "Down:1")
var scroll_direction: int = 0
## Players will control themselves if enabled
@export var botplay: bool = false

@export_group("Visual Options")
## Define here your frames per second limit.
@export var framerate_cap: int = 60:
	set(new_framerate):
		framerate_cap = clampi(new_framerate, 30, 240)
		if framerate_mode == "Capped":
			Engine.max_fps = framerate_cap
## Define how the engine should treat framerate.
@export_enum("Capped", "Unlimited", "VSync")
var framerate_mode: String = "Capped":
	set(new_mode):
		if new_mode == "VSync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			if new_mode == "Unlimited":
				Engine.max_fps = 0
		framerate_mode = new_mode

## Enables a firework effect when hitting judgements that allow it.
@export var note_splashes: bool = true

#region Functions

func _ready() -> void:
	init_keybinds()


func init_keybinds() -> void:
	for action_name: String in keybinds:
		for i: int in keybinds.get(action_name).size():
			var action_player: StringName = StringName(action_name + "_p%s" % str(i + 1))
			if InputMap.has_action(action_player):
				InputMap.action_erase_events(action_player)

			var key: String = keybinds.get(action_name)[i]
			var _new_event: = InputEventKey.new()
			_new_event.keycode = OS.find_keycode_from_string(key.to_lower())
			InputMap.action_add_event(action_player, _new_event)

#endregion
