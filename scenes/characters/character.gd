extends AnimatedSprite2D
## ...
class_name Character

@export_category("Character")

## Quite self-explanatory.
@export var display_name: StringName = "Nameless"
## Current animation suffix, defaults to ""
@export var animation_suffix: String = ""
## Current animation context, defualts to Dancing ([code]0[/code])
@export_enum("Dancing:0", "Singing:1", "Special:2")
var animation_content: int = 0

@export_category("Animations")

## List of idles, cycled through every [code]beat_interval[/code] beats
@export var idle_list: PackedStringArray = ["idle"]
## List of sing animations, used when hitting notes.
@export var sing_list: PackedStringArray = ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
## Interval (in beats) for characters to [code]dance()[/code]
@export var dance_interval: int = 2

var _current_idle: int = 0
var _previous_anim: StringName = ""


func dance(forced: bool = false, force_idle: int = -1) -> void:
	if force_idle > -1 and force_idle < idle_list.size():
		_current_idle = force_idle

	#play_animation(idle_list[_current_idle], forced)
	_current_idle = wrapi(_current_idle + 1, 0, idle_list.size())
