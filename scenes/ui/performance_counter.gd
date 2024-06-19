extends CanvasLayer

@onready var perf_label:  = $"ui/perf_label"
@onready var update_timer: = $"update_timer"
var _debug_display: bool = false
var _update_delay: float = 1.0


func _ready() -> void:
	update_timer.start(_update_delay)
	update_timer.timeout.connect(func():
		update_text()
		update_timer.start(_update_delay)
	)
	update_text()


func update_text() -> void:
	perf_label.text = ""
	if _debug_display:
		perf_label.text += "			- Performance -\n"

	perf_label.text += "[font_size=18]%s[/font_size] FPS" % Performance.get_monitor(Performance.TIME_FPS)
	if OS.is_debug_build():
		perf_label.text += "\n[font_size=18]%s[/font_size] RAM\n" % [
			String.humanize_size(int(Performance.get_monitor(Performance.MEMORY_STATIC)))]

	if _debug_display:
		perf_label.text += "\n			- Conductor -\n"
		perf_label.text += "\n[font_size=15]%s[/font_size]" % Conductor.to_string()


func _unhandled_key_input(e: InputEvent) -> void:
	if e.pressed: match e.keycode:
		KEY_F3:
			_debug_display = not _debug_display
			var conductor_delta: float = 0.8 * Conductor.semiquaver
			_update_delay = 1.0 if not _debug_display else conductor_delta
			update_text()
		KEY_F4:
			Conductor.rate -= 0.01
			print_debug(Conductor.rate)
		KEY_F5:
			Conductor.rate += 0.01
			print_debug(Conductor.rate)
		KEY_F11:
			match DisplayServer.window_get_mode():
				DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				_: # anything but fullscreen
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
