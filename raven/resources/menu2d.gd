class_name Menu2D extends Node2D
#region Constants
const CONFIRM_SOUND: AudioStream = preload("res://assets/audio/sfx/menu/confirmMenu.ogg")
const SCROLL_SOUND: AudioStream = preload("res://assets/audio/sfx/menu/scrollMenu.ogg")
const CANCEL_SOUND: AudioStream = preload("res://assets/audio/sfx/menu/cancelMenu.ogg")
#endregion

#region Selectors
var selected: int = 0
var alternative: int = 0

var total_selectors: int = 0
var total_alternatives: int = 0
#endregion
var can_open_options: bool = false

#region Functions
func _unhandled_key_input(_e: InputEvent):
	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	var lr: int = int(Input.get_axis("ui_left", "ui_right"))
	if ud != 0: update_selection(ud)
	if lr != 0: update_alternative(lr)

func update_selection(new: int = 0):
	if total_selectors < 2: return
	selected = wrapi(selected + new, 0, total_selectors)

func update_alternative(new: int = 0):
	if total_alternatives < 2: return
	alternative = wrapi(alternative + new, 0, total_alternatives)
#endregion
