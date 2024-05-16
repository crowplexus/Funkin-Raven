extends Node

#region INTERNAL VARIABLES
enum _LANGS {
	en = 0,
	pt = 1,
	es = 2,
	#jp = 3,
}
const _CONFIG_PATH: String = "user://config.cfg"
var _cfg: ConfigFile
#endregion

#region Gameplay

## Defines the Direction of which the Notes scroll to.
@export_enum("Up:0", "Down:1", "Split UD:2", "Split DU:3")
var scroll: int = 0
## Prevents damage if you try to hit notes while you can't.
var ghost_tapping: bool = true
## Your (note) keybinds.
var keybinds: Array[Array] = [
	["A", "S", "W", "D"], # Player 1
	["Left", "Down", "Up", "Right"], # Player 2 / Player 1 Alts
]:
	set(v):
		keybinds = v
		Settings.keybind_check()
## Defines the notes scroll speed, dictated by [code]Settings.speed_mode[/colde]
var scroll_speed: float = 1.0:
	set(v): scroll_speed = wrapf(v, 0.5, 5.0)
## Defines the note's scroll speed type.
@export_enum("None:0", "Constant:1", "Multiplicative:2")#, "BPM-Based: 2")
var speed_mode: int = 0
## Note offset during gameplay.
var note_offset: float = 0.0:
	set(v): note_offset = clampf(v, -1.0, 1.0)

#endregion

#region Gameplay Modifiers

## Enables autoplay mode during gameplay, which makesthe game play itself.[br]
## will invalidate your score.
var autoplay: bool = false
## Enables practice mode, which disables dying and missing[br]
## will invalidate your score.
var practice: bool = false
## Enables enemy play, need further explanation?
var enemy_play: bool = false
## Choose the calculation mode of your Accuracy.
@export_enum("Judgement-based:0", "Timing-based (Wife3):1")
var accuracy_calculator: int = 0
## Implements a secondary health system with a miss limit[br]
## Defined by the set number, when you reach the limit, you die.
var miss_limiter: int = 0:
	set(v): miss_limiter = wrapi(v, 0, 16)

## Defines the timings to hit certain judgements.
var timings: Array[float] = []

## a 5th rating, makes the game harder, go wild!
var use_epics: bool = true
## Enables a combo multiplier, which multiplies your score gain.
var enable_combo_multiplier: bool = true
## Define the combo multiplier's requirement,[br]
## where it begins to act up when your combo matches the set number.
var combo_mult_weight: int = 25:
	set(weight): combo_mult_weight = wrapi(weight, 20, 51)

#endregion

#region Graphics and Sounds

## Defines the style of your notes.
var note_skin: StringName = "fnf"
## Defines how dynamically-colored skins should be colored.
@export_enum("Column:0", "Quant:1")
var note_colour_mode: int = 0
## Places a judgement counter somewhere on-screen.
@export_enum("None:0", "Left:1", "Right:2")
var judgement_counter: int = 1

## Guess this explains itself.
var framerate: int = 120:
	set(v):
		framerate = wrapi(v, 30, 241)
		Engine.max_fps = framerate

@export_enum("Capped:0", "VSync:1", "Unlimited:2")
## How should we limit your framerate?
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
## Pops a firework effect whenever you hit "Sick"s.
var note_splashes: bool = true
## Defines the opacity of the Note Splashes.
var note_splash_a: int = 80:
	set(a): note_splash_a = clampi(a, 0, 100)
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
		var v: StringName = icon_bump_style.to_snake_case()

		var path: String = "res://raven/ui/play/icons/%s.gd" % v
		if not ResourceLoader.exists(path):
			path = path.replace("res://raven/ui/play/icons", "user://scripts/icons")
			if not ResourceLoader.exists(path):
				path = "res://raven/ui/play/icons/default.gd"

		match icon_bump_style: # if you ever wanna add a custom value
			_: return load(path)

## Where should the judgements and combo be placed?
@export_enum("In Stage:0", "In HUD:1")
var judgement_placement: int = 1

## How should the accuracy be displayed in the score text?
@export_enum("Common:0", "ITG-Style:1")
var accuracy_display_style: int = 0

## How should the healthbar be colored?
@export_enum("By Character:0", "Red and Lime:1", "Red and Player:1", "Enemy and Lime:2")
var health_bar_color_style: int = 0

#endregion

#region Engine

## Defines your language, used throuought the game's menus and interface.
var language: int = 0:
	set(v):
		language = v
		var lang_str: StringName = _LANGS.keys()[v].to_lower()
		TranslationServer.set_locale(lang_str)
## Skips transitions during playthrough.
var skip_transitions: bool = false
## Enables flashing effects in-game, disable this if you're photosensitive
var flashing_lights: bool = true
## Makes the camera zoom back and forth.
var camera_zooms: bool = true
## Makes the hud bump back and forth.
var hud_bumping: bool = true
## Will show how you performend after gameplay.
var show_eval_screen: bool = true

#endregion

#region FUNCTIONS

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#303030"))
	load_settings()

func save_settings() -> void:
	_is_cfg_loaded()

	var properties: Array[Dictionary] = get_property_list()
	for i: int in 19: properties.remove_at(0)
	for preference in properties:
		if preference.name.begins_with("_") or get(preference.name) == null: continue
		_cfg.set_value("Settings", preference.name, get(preference.name))

	#print_debug("Settings Saved [", Time.get_datetime_string_from_system(), "]")
	_cfg.save(_CONFIG_PATH)

func load_settings() -> void:
	_is_cfg_loaded()
	var properties: Array[Dictionary] = get_property_list()
	for i: int in 19: properties.remove_at(0)
	for preference in properties:
		if preference.name.begins_with("_") or get(preference.name) == null: continue
		_save_or_load_pref(preference.name)

func keybind_check() -> void:
	Input.set_use_accumulated_input(false)
	# disgustingly hardcoded
	var notes: Array[String] = ["note_l", "note_d", "note_u", "note_r"]

	for i: int in notes.size():
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

func _is_cfg_loaded() -> bool:
	if _cfg == null: _cfg = ConfigFile.new()
	var e: Error = _cfg.load(_CONFIG_PATH)
	return e == OK

func _save_or_load_pref(pref: String) -> void:
	if not _cfg.has_section_key("Settings", pref):
		_cfg.set_value("Settings", pref, get(pref))
	else:
		set(pref, _cfg.get_value("Settings", pref, get(pref)))

func _save_pref(pref: String) -> void:
	_cfg.set_value("Settings", pref, get(pref))

#endregion
