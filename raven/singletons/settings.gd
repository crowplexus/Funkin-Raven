extends Node

#region INTERNAL VARIABLES
enum _LANGS {
	EN = 0,
	PT = 1,
	ES = 2,
	#JP = 3,
}
const _CONFIG_PATH: String = "user://config.cfg"
var _cfg: ConfigFile
#endregion

#region Gameplay

## Defines the Direction of which the Notes scroll to.
@export_enum("Up:0", "Down:1", "Split UD:2", "Split DU:3")
var scroll: int = 0
## If tapping while no notes are present should give misses or not.
var ghost_tapping: bool = true
## Your (note) keybinds.
var keybinds: Array[Array] = [
	["A", "S", "W", "D"], # Player 1
	["Left", "Down", "Up", "Right"], # Player 2 / Player 1 Alts
]:
	set(v):
		keybinds = v
		Settings.keybind_check()
## Custom Note Speed.
var scroll_speed: float = 1.0:
	set(v): scroll_speed = wrapf(v, 0.5, 5.0)
## Mode of which is used with Custom Note Speed.
@export_enum("None:0", "Constant:1", "Multiplicative:2")#, "BPM-Based: 2")
var speed_mode: int = 0

#endregion

#region Gameplay Modifiers

## Enables autoplay mode during gameplay[br]
## which make the game play itself, diregarding player input[br]
## will invalidate your score.
var autoplay: bool = false
## Enables practice mode during gameplay[br]
## which disables dying and missing[br]
## will invalidate your score.
var practice: bool = false
## Enablles enemy play, which allows you to olay as your enemy.[br]
## Requires restart if you are already playing.
var enemy_play: bool = false
## Implements a secondary health system with a miss limit[br]
## Defined by the set number, when you reach the limit, you die.
var miss_limiter: int = 0:
	set(v):
		miss_limiter = wrapi(v, 0, 16)

## Sets the difficulty of the timing for your judgements.[br]
## The higher the number, the tighter it gets to hit a good judgement.
@export_enum("Judge 4:0", "Judge 5:1", "Funkin:2", "NotITG:3", "Freestyle:4")
var judgement_difficulty: int = 1
## Enables the new 5th judgement, called "Epic"[br]
## Disable this if you prefer fnf's 4 ratings.
var enable_epics: bool = true

#endregion

#region Graphics and Sounds

## Defines the Framerate Cap the game should runs at.
var framerate: int = 120:
	set(v):
		framerate = wrapi(v, 30, 241)
		Engine.max_fps = framerate

@export_enum("Capped:0", "VSync:1", "Unlimited:2")
## Mode used to define how the Engine Framerate behaves.
var framerate_mode: int = 0:
	set(v):
		framerate_mode = v
		var value := DisplayServer.VSYNC_DISABLED
		if v == 1: value = DisplayServer.VSYNC_ADAPTIVE
		DisplayServer.window_set_vsync_mode(value)
		Engine.max_fps = framerate if v == 0 else 0

## Hides the stage background from the main gameplay.
var hide_stage: bool = false
## Hides characters from the main gameplay.
var hide_characters: bool = false
## If when hitting "Sick!" Notes, the firework effect should appear.
var splashes: bool = true
## Game's (Master) Volume.
var volume: int = 100:
	set(v):
		volume = clampi(v, 0, 100)
		AudioServer.set_bus_volume_db(0, linear_to_db(v*0.01))
## Defines how the icons should bump forward on beats.
@export_enum("Default:0", "Arrow Funk:1", "Base-like:2")
var icon_bump_style: String = "Default"
var icon_bump_script: GDScript:
	get: # readonly
		var v: String = icon_bump_style.to_snake_case()
		
		var path: String = "res://raven/game/ui/icons/%s.gd" % v
		if not ResourceLoader.exists(path):
			path = path.replace("res://raven/game/ui/icons", "user://scripts/icons")
			if not ResourceLoader.exists(path):
				path = "res://raven/game/ui/icons/default.gd"
		
		match icon_bump_style: # if you ever wanna add a custom value
			_: return load(path)

## Where should the judgements and combo be placed?
@export_enum("World:0", "HUD:1")
var judgement_placement: int = 1
#endregion

#region Engine

## Defines your language, used throuought the game's menus and interface.
var language: int = 0:
	set(v):
		language = v
		var lang_str: StringName = _LANGS.keys()[v].to_lower()
		TranslationServer.set_locale(lang_str)
## If transitions should be skipped during playthrough.
var skip_transitions: bool = false
## If during navigation and gameplay, flashing lights should be allowed.
var flashing_lights: bool = true
## If during gameplay, the camera should bump forward and back.
var camera_zooms: bool = true
## If during gameplay, the HUD should bump forward and back.
var hud_bumping: bool = true
## After a song ends, an evaluation screen will pop up[br]
## Displaying your performance during gameplay.
var show_eval_screen: bool = true

#endregion

#region FUNCTIONS

func _ready():
	RenderingServer.set_default_clear_color(Color("#303030"))
	load_settings()

func save_settings():
	_is_cfg_loaded()
	
	var properties: Array[Dictionary] = get_property_list()
	for i in 19: properties.remove_at(0)
	for preference in properties:
		if preference.name.begins_with("_") or get(preference.name) == null: continue
		_cfg.set_value("Settings", preference.name, get(preference.name))
	
	#print_debug("Settings Saved [", Time.get_datetime_string_from_system(), "]")
	_cfg.save(_CONFIG_PATH)

func load_settings():
	_is_cfg_loaded()
	var properties: Array[Dictionary] = get_property_list()
	for i in 19: properties.remove_at(0)
	for preference in properties:
		if preference.name.begins_with("_") or get(preference.name) == null: continue
		_save_or_load_pref(preference.name)

func keybind_check():
	Input.set_use_accumulated_input(false)
	# disgustingly hardcoded
	var notes :Array[String] = ["note_l", "note_d", "note_u", "note_r"]
	
	for i in notes.size():
		var action: String = notes[i]
		var events: = InputMap.action_get_events(action)
		
		var event1 :InputEventKey = InputEventKey.new() # normal bind
		var event2 :InputEventKey = InputEventKey.new() # alt bind
		
		event1.set_keycode(OS.find_keycode_from_string(Settings.keybinds[0][i]))
		event2.set_keycode(OS.find_keycode_from_string(Settings.keybinds[1][i]))
		
		if events.size()-1 != -1: # error handling shit
			for j in events: InputMap.action_erase_event(action, j)
		else: InputMap.add_action(action)
			
		InputMap.action_add_event(action, event1)
		InputMap.action_add_event(action, event2)

func _is_cfg_loaded():
	if _cfg == null: _cfg = ConfigFile.new()
	var e: Error = _cfg.load(_CONFIG_PATH)
	return e == OK

func _save_or_load_pref(pref: String):
	if not _cfg.has_section_key("Settings", pref):
		_cfg.set_value("Settings", pref, get(pref))
	else:
		set(pref, _cfg.get_value("Settings", pref, get(pref)))

#endregion
