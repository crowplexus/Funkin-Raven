extends Node

const MENU_MUSIC: AudioStream = preload("res://assets/audio/bgm/freakyMenu.ogg")
const MENU_MUSIC_BPM: float = 102.0

const MENU_SCROLL_SFX: AudioStream = preload("res://assets/audio/sfx/menu/scrollMenu.ogg")
const MENU_CONFIRM_SFX: AudioStream = preload("res://assets/audio/sfx/menu/confirmMenu.ogg")
const MENU_CANCEL_SFX: AudioStream = preload("res://assets/audio/sfx/menu/cancelMenu.ogg")
const OPTIONS_WINDOW: PackedScene = preload("res://scenes/ui/options_window.tscn")


func change_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)


func get_options_window() -> Control:
	var ow: Control = OPTIONS_WINDOW.instantiate()
	ow.process_mode = Node.PROCESS_MODE_ALWAYS
	ow.z_index = 100
	return ow

#region Number Related Functions
func format_to_time(value: float) -> String:
	var formatter: String = "%02d:%02d" % [
		float_to_minute(value),
		float_to_seconds(value)
	]

	var hours: int = float_to_hours(value)
	if hours != 0: # append hours if needed
		formatter = ("%02d:" % hours) + formatter
	return formatter

func float_to_hours(value: float) -> int: return int(value / 3600.0)
func float_to_minute(value: float) -> int: return int(value / 60) % 60
func float_to_seconds(value: float) -> float: return fmod(value, 60)
#endregion
