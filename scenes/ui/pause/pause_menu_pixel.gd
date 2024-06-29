extends "res://scenes/ui/pause/pause_menu.gd"

@onready var pixel_box: ColorRect = $"boxy_box"
@onready var pixel_options: Label = $"boxy_box/options"
@onready var selector: Label = $"boxy_box/selector"
var initial_box_pos: Vector2 = Vector2.ZERO
var _time_wasted: float = 0.0


func _ready() -> void:
	if get_tree().current_scene != self:
		Globals.set_node_inputs(get_tree().current_scene, false)
	initial_box_pos = pixel_box.position
	options_len = pixel_options.get_line_count()

	back.modulate.a = 0.0
	create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE) \
	.tween_property(back, "modulate:a", 0.6, 0.4)

	setup_music()
	setup_level_label()
	update_selection()


func _process(delta: float) -> void:
	if pixel_box:
		_time_wasted += delta
		var floaty: float = (sin(_time_wasted * PI) * 2.5)
		pixel_box.position.y = initial_box_pos.y + floaty
	if selector:
		var pos: float = selector.size.y + 45 * current_selection
		selector.position.y = pos


func setup_level_label() -> void:
	if Chart.global and Chart.global.song_info:
		$"boxy_box/level_label".text = "Song: %s\nDifficulty: %s\nFails: %s" % [
			Chart.global.song_info.name, Chart.global.song_info.difficulty.display_name,
			"0"]


func update_selection(new: int = 0) -> void:
	current_selection = wrapi(current_selection + new, 0, options_len)
	if new != 0: SoundBoard.play_sfx(Globals.MENU_SCROLL_SFX)
