extends Node

const STARTING_SCENE: PackedScene = preload("res://scenes/menu/title_screen.tscn")
const MENU_MUSIC: AudioStream = preload("res://assets/audio/bgm/menu/freakyMenu.ogg")
const RANDOM_MUSIC: AudioStream = preload("res://assets/audio/bgm/menu/freeplayRandom.ogg")
const MENU_MUSIC_BPM: float = 102.0

const MENU_SCROLL_SFX: AudioStream = preload("res://assets/audio/sfx/menu/scrollMenu.ogg")
const MENU_CONFIRM_SFX: AudioStream = preload("res://assets/audio/sfx/menu/confirmMenu.ogg")
const MENU_CANCEL_SFX: AudioStream = preload("res://assets/audio/sfx/menu/cancelMenu.ogg")
const OPTIONS_WINDOW: PackedScene = preload("res://scenes/ui/options/options_window.tscn")

const DEFAULT_HUD: PackedScene = preload("res://scenes/gameplay/hud/default.tscn")
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
	KEY_F11: func():
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_: # anything but fullscreen
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
}

#region Node Funcs

func _unhandled_key_input(e: InputEvent) -> void:
	if e.is_pressed():
		for k: Variant in special_keybinds:
			if e.keycode == k and special_keybinds[k] is Callable:
				special_keybinds[k].call_deferred()

#endregion

#region Scenes

func change_scene(scene: PackedScene, skip_transition: bool = false) -> void:
	if not skip_transition: await Transition.play_in()
	get_tree().change_scene_to_packed(scene)
	if not skip_transition: await Transition.play_out()


func reset_scene(skip_transition: bool = false) -> void:
	if not skip_transition: await Transition.play_in("fade")
	get_tree().reload_current_scene()
	if not skip_transition: await Transition.play_out("fade")


func get_options_window() -> Control:
	var ow: Control = OPTIONS_WINDOW.instantiate()
	ow.process_mode = Node.PROCESS_MODE_ALWAYS
	ow.z_index = 100
	return ow

## Handy function to enable / disable all input functions for a node.
func set_node_inputs(node: Node, enable: bool) -> void:
	node.set_process_input(enable)
	node.set_process_shortcut_input(enable)
	node.set_process_unhandled_input(enable)
	node.set_process_unhandled_key_input(enable)

#endregion
#region Text

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
#region Number Related Functions
func format_to_time(value: float) -> String:
	var minutes: float = Globals.float_to_minute(value)
	var seconds: float = Globals.float_to_seconds(value)
	var formatter: String = "%2d:%02d" % [minutes, seconds]
	var hours: int = Globals.float_to_hours(value)
	if hours != 0: # append hours if needed
		formatter = ("%2d:%02d:02d" % [hours, minutes, seconds])
	return formatter

func float_to_hours(value: float) -> int: return int(value / 3600.0)
func float_to_minute(value: float) -> int: return int(value / 60) % 60
func float_to_seconds(value: float) -> float: return fmod(value, 60)
#endregion
#region Canvas Item

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
