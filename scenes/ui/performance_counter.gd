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
