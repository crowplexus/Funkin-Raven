class_name Menu2D extends Node2D
#region Constants

const DEFAULT_MENU_MUSIC: AudioStream = preload("res://assets/audio/bgm/freakyMenu.ogg")
const CONFIRM_SOUND: AudioStream = preload("res://assets/audio/sfx/menu/confirmMenu.ogg")
const SCROLL_SOUND: AudioStream = preload("res://assets/audio/sfx/menu/scrollMenu.ogg")
const CANCEL_SOUND: AudioStream = preload("res://assets/audio/sfx/menu/cancelMenu.ogg")

#endregion

#region Selectors

var selected: int = 0
var alternative: int = 0
var voptions: Array = []
var hoptions: Array = []

#endregion
var can_open_options: bool = false

#region Functions
func _unhandled_key_input(_e: InputEvent) -> void:
	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	var lr: int = int(Input.get_axis("ui_left", "ui_right"))
	if ud: update_selection(ud)
	if lr: update_alternative(lr)

	if can_open_options:
		if Input.is_key_label_pressed(KEY_MENU):
			self.process_mode = Node.PROCESS_MODE_DISABLED
			add_child(Tools.get_options_window())

func update_selection(new: int = 0) -> void:
	if voptions.size() < 2: return
	selected = wrapi(selected + new, 0, voptions.size())

func update_alternative(new: int = 0) -> void:
	if hoptions.size() < 2: return
	alternative = wrapi(alternative + new, 0, hoptions.size())
#endregion
