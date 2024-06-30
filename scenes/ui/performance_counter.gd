extends CanvasLayer

@onready var perf_label:  = $"ui/perf_label"
@onready var volume_bar: ProgressBar = $"ui/volume_bar"
@onready var bus_label: Label = $"ui/volume_bar/bus_label"
@onready var volume_sfx: ResourcePreloader = $"volume_sounds"
@onready var update_timer: Timer = $"update_timer"

var _cur_bus: int = 0
var _display_state: int = 0
var _game_muted: bool = false:
	set(mute): AudioServer.set_bus_mute(_cur_bus, mute)
var _update_delay: float = 1.0
var _volume_bar_tween: Tween


func _ready() -> void:
	volume_bar.modulate.a = 0.0
	update_timer.start(_update_delay)
	update_timer.timeout.connect(func():
		update_text()
		update_timer.start(_update_delay)
	)
	update_bus(0, true)
	update_text()


func update_text() -> void:
	perf_label.text = ""
	if _display_state == 1:
		perf_label.text += "			- Performance -\n"

	perf_label.text += "[font_size=18]%s[/font_size] FPS" % Performance.get_monitor(Performance.TIME_FPS)
	if OS.is_debug_build():
		perf_label.text += "\n[font_size=18]%s[/font_size] RAM\n" % [
			String.humanize_size(int(Performance.get_monitor(Performance.MEMORY_STATIC)))]

	if _display_state == 1:
		perf_label.text += "\n			- Conductor -\n"
		perf_label.text += "\n[font_size=15]%s[/font_size]" % Conductor.to_string()


func _unhandled_key_input(e: InputEvent) -> void:
	if e.pressed: match e.keycode:
		KEY_EQUAL:
			if _game_muted:
				_game_muted = false
			if volume_bar.modulate.a == 0.0:
				update_volume_bar()
				return
			set_bus_volume(_cur_bus, get_bus_volume(_cur_bus) + 0.05)
			update_volume_bar()
		KEY_MINUS:
			if _game_muted:
				_game_muted = false
			if volume_bar.modulate.a == 0.0:
				update_volume_bar()
				return
			set_bus_volume(_cur_bus, get_bus_volume(_cur_bus) - 0.05)
			update_volume_bar()
		KEY_0:
			_game_muted = not _game_muted
			update_volume_bar()
		KEY_TAB when volume_bar.modulate.a > 0.0:
			update_bus(1, true)


func update_volume_bar(quiet: bool = false) -> void:
	if _volume_bar_tween:
		_volume_bar_tween.stop()

	if not quiet:
		if volume_bar.modulate.a == 0.0:
			SoundBoard.play_sfx(volume_sfx.get_resource("volume_appear"), 0.3)
		else:
			var pitch: float = 0.8
			SoundBoard.play_sfx(volume_sfx.get_resource("volume_change"), 0.3, pitch)

	volume_bar.modulate.a = 1.0
	volume_bar.value = get_bus_volume(_cur_bus) * volume_bar.max_value
	update_bus_label()

	Preferences.save_pref(get_bus_pref(_cur_bus), get_bus_volume(_cur_bus))
	_volume_bar_tween = create_tween().set_ease(Tween.EASE_OUT)
	_volume_bar_tween.tween_property(volume_bar, "modulate:a", 0.0, 1.0) \
	.set_delay(0.5)


func update_bus(next: int = 0, quiet: bool = false) -> void:
	_cur_bus = wrapi(_cur_bus + next, 0, AudioServer.bus_count)
	update_volume_bar(quiet)


func update_bus_label() -> void:
	bus_label.text = "%s\nBus: %s%s\n[TAB]" % [
		"%d%%" % [volume_bar.value],
		AudioServer.get_bus_name(_cur_bus),
		"(MUTE)" if _game_muted else "",
	]


func get_bus_pref(idx: int) -> String:
	match idx:
		1: return "bgm_volume"
		2: return "sfx_volume"
		_: return "master_volume"


func get_bus_volume(idx: int) -> float:
	match idx:
		1: return Preferences.bgm_volume
		2: return Preferences.sfx_volume
		_: return Preferences.master_volume


func set_bus_volume(idx: int, vol: float) -> void:
	match idx:
		0: Preferences.master_volume = vol
		1: Preferences.bgm_volume = vol
		2: Preferences.sfx_volume = vol



