extends Node

const STARTING_SCENE: PackedScene = preload("res://scenes/menu/title_screen.tscn")
const MENU_MUSIC: AudioStream = preload("res://assets/audio/bgm/menu/freakyMenu.ogg")
const RANDOM_MUSIC: AudioStream = preload("res://assets/audio/bgm/menu/freeplayRandom.ogg")
const CREDITS_MUSIC: AudioStream = preload("res://assets/audio/bgm/menu/freeplayRandom.ogg")
const MENU_MUSIC_BPM: float = 102.0

const MENU_SCROLL_SFX: AudioStream = preload("res://assets/audio/sfx/menu/scrollMenu.ogg")
const MENU_CONFIRM_SFX: AudioStream = preload("res://assets/audio/sfx/menu/confirmMenu.ogg")
const MENU_CANCEL_SFX: AudioStream = preload("res://assets/audio/sfx/menu/cancelMenu.ogg")
const OPTIONS_WINDOW: PackedScene = preload("res://scenes/ui/options/options_window.tscn")

const DEFAULT_HUD: PackedScene = preload("res://scenes/gameplay/hud/raven.tscn")
const DEFAULT_STAGE: PackedScene = preload("res://scenes/backgrounds/mainStage.tscn")
const DEFAULT_SKIN: UISkin = preload("res://assets/sprites/ui/normal.tres")

var ENGINE_VERSION: String:
	get: return ProjectSettings.get_setting("application/config/version")

var special_keybinds: Dictionary = {
	KEY_F3: func():
		PerformanceCounter._display_state = wrapi(PerformanceCounter._display_state + 1, 0, 3)
		PerformanceCounter.visible = PerformanceCounter._display_state < 2
		var conductor_delta: float = 0.8 * Conductor.semiquaver
		PerformanceCounter._update_delay = 1.0 if PerformanceCounter._display_state != 1 else conductor_delta
		PerformanceCounter.update_text(),
	KEY_F5: func():
		Globals.reset_scene(true),
}

#region Node Funcs

func _ready() -> void:
	Highscore.cached_hi = Highscore.open()

func _unhandled_key_input(e: InputEvent) -> void:
	if e.is_pressed() and  e.keycode in special_keybinds:
		for k: Variant in special_keybinds:
			if special_keybinds[k] is Callable:
				special_keybinds[k].call_deferred()
	if Input.is_action_just_pressed("ui_fullscreen"):
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_: # anything but fullscreen
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

#endregion

#region Scenes

func change_scene(scene: PackedScene, skip_transition: bool = false) -> void:
	if not skip_transition:
		get_tree().paused = true
		await Transition.play_in()
	get_tree().change_scene_to_packed(scene)
	if not skip_transition:
		await Transition.play_out()
		get_tree().paused = false

func reset_scene(skip_transition: bool = false) -> void:
	if not skip_transition:
		get_tree().paused = true
		await Transition.play_in("fade")
	get_tree().reload_current_scene()
	if not skip_transition:
		await Transition.play_out("fade")
		get_tree().paused = false

func get_options_window() -> Control:
	var ow: Control = OPTIONS_WINDOW.instantiate()
	ow.process_mode = Node.PROCESS_MODE_ALWAYS
	ow.z_index = 100
	return ow

## Handy function to enable / disable all input functions for a node.
func set_node_inputs(node: Node, enable: bool) -> void:
	node.set_process_unhandled_key_input(enable)
	node.set_process_unhandled_input(enable)
	node.set_process_shortcut_input(enable)
	node.set_process_input(enable)

#endregion
#region Strings

## Formats integer strings going up to thousands.[br]
## @tutorial:			https://www.reddit.com/r/godot/comments/9iw4ie/comment/e6n7r8k/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
func thousands_sep(number: int, separator: String = ","):
	var neg: bool = signi(number) < 0
	var num_str: String = str(abs(number))
	var length: int = num_str.length()
	var neg_prefix: String = "-" if neg else ""
	if length <= 3: # no reason to do this if there's less than 3 digits
		return "%s" % [neg_prefix + num_str]
	var mod: float = length % 3
	var res: String = ""
	for i in range(0, num_str.length()):
		if i != 0 and i % 3 == mod:
			res += separator
		res += num_str[i]
	return neg_prefix + res

## Converts text to a dictionary[br]
## Format (in text string):[br]
##	"Dictionary Key,Value"[br]
##	"," can be replaced by [code]separator[/code]
func text_to_dictionary(text: String, separator: String = ",") -> Dictionary:
	var data: Dictionary = {}
	for line: String in text.dedent().	strip_edges().split("\n"):
		if line.begins_with("#"):
			continue
		var split_line: PackedStringArray = line.split(separator)
		var cur_node: String = ""
		for i: int in split_line.size():
			var thingy: String = split_line[i]
			if i == 0: cur_node = thingy
			if not cur_node.is_empty():
				data[cur_node] = thingy
	return data

#endregion
#region Numbers
func format_to_time(value: float) -> String:
	var minutes: float = Globals.float_to_minute(value)
	var seconds: float = Globals.float_to_seconds(value)
	var formatter: String = "%2d:%02d" % [minutes, seconds]
	var hours: int = Globals.float_to_hours(value)
	if hours != 0: # append hours if needed
		formatter = ("%2d:%02d:02d" % [hours, minutes, seconds])
	return formatter

func get_weekday_string() -> String:
	var weekday: Time.Weekday = Time.get_date_dict_from_system().weekday
	match weekday:
		0: return "Sunday"
		1: return "Monday"
		2: return "Tuesday"
		3: return "Wednesday"
		4: return "Thursday"
		5: return "Friday"
		_: return "Unknown"

func float_to_hours(value: float) -> int: return int(value / 3600.0)
func float_to_minute(value: float) -> int: return int(value / 60) % 60
func float_to_seconds(value: float) -> float: return fmod(value, 60)
#endregion
#region Canvas Items

func begin_flicker(node: CanvasItem, duration: float = 1.0, interval: float = 0.04,
	end_vis: bool = false, force: bool = false, finish_callable: Callable = func() -> void: pass) -> void:
	####
	if node == null: return
	if force: node.self_modulate.a = 1.0

	var twn: Tween = create_tween()
	twn.set_loops(int(duration/interval))
	twn.bind_node(node)

	twn.finished.connect(func() -> void:
		node.self_modulate.a = 1.0 if end_vis else 0.0
		if finish_callable != null:
			finish_callable.call()
	)

	twn.tween_callback(func() -> void:
		var val: float = 1.0 if node.self_modulate.a < 1.0 else 0.0
		node.self_modulate.a = val
	).set_delay(interval)

#endregion
