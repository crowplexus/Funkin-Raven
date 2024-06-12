extends Node

@export var botplay: bool = false
@export var keybinds: Dictionary = {
	"note0": [	"S",	"Left"	],
	"note1": [	"D",	"Down"	],
	"note2": [	"K",	"Up"	],
	"note3": [	"L",	"Right"	],
}

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
