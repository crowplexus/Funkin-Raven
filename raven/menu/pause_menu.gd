extends Control

@onready var bg: ColorRect = $bg
@onready var items: Control = $items
@onready var level_info: Label = $level_info
@onready var play_info: Label = $play_info

var selected: int = 0
var default_list: Array[String] = [
	tr("pause_resumebutton"), tr("pause_restartbutton"),
	tr("pause_changeoptions"), tr("pause_exitbutton")
]
var current_list: Array[String] = []
var exit_callback: Callable

var screenshot_mode: bool = false

var visi_tween: Tween

func _ready() -> void:
	self.top_level = true
	current_list = default_list
	bg.modulate.a = 0.0

	var pause_stream: AudioStream = load("res://assets/audio/bgm/breakfast.ogg") as AudioStream
	SoundBoard.play_track(pause_stream, true, 0.01, randf_range(0.0, pause_stream.get_length() * 0.5))

	if PlayField.chart != null:
		level_info.text = "%s\n%s\n" % [
			tr("pause_songinfo") % PlayField.song_data.name,
			tr("pause_diffinfo") % tr(Progression.difficulty.to_lower()).to_upper(),
		]
		if Conductor.time >= 0.0:
			level_info.text += "%s\n" %[
				tr("pause_timeinfo") % [ Tools.format_to_time(Conductor.time),
					Tools.format_to_time(Conductor.length), ],
			]

	create_tween().set_trans(Tween.TRANS_CUBIC) \
	.tween_property(bg, "modulate:a", 1.6, 0.5)

	var total: int = level_info.get_total_character_count()
	level_info.visible_characters = 0
	play_info.modulate.a = 0.0
	reload_play_info()

	create_tween().bind_node(level_info).set_trans(Tween.TRANS_QUART) \
	.tween_property(level_info, "visible_characters", total, 1.25)

	create_tween().bind_node(play_info).set_ease(Tween.EASE_IN) \
	.tween_property(play_info, "modulate:a", 1.0, 0.8) \
	.set_delay(0.5)

	_reload_list(current_list)

func _process(_delta: float) -> void:
	if SoundBoard.bg_tracks.volume_db < linear_to_db(0.5):
		SoundBoard.bg_tracks.volume_db += 0.01

func _unhandled_key_input(_e :InputEvent) -> void:
	if _e.is_pressed() and _e.keycode == KEY_F1:
		screenshot_mode = not screenshot_mode
		self.visible = not screenshot_mode

	# lock inputs (except f2) if on screenshot mode
	if screenshot_mode == true:
		return

	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	if ud: update_selection(ud)

	if Input.is_action_just_pressed("ui_accept"):
		match selected:
			0:
				await unpause()
				queue_free()
			1:
				PlayField.play_manager.reset()
				$"../".process_mode = Node.PROCESS_MODE_DISABLED
				await unpause()
				Tools.refresh_scene(true)
			2:
				self.process_mode = Node.PROCESS_MODE_DISABLED
				add_child(Tools.get_options_window(func() -> void:
					if OptionsBar.will_restart_gameplay:
						OptionsBar.will_restart_gameplay = false
						$"../".process_mode = Node.PROCESS_MODE_DISABLED
						PlayField.play_manager.reset()

						await unpause()
						Tools.refresh_scene(true)
				))
			3:
				PlayField.death_count = 0
				PlayField.play_manager.reset()
				$"../".process_mode = Node.PROCESS_MODE_DISABLED
				var next_menu: StringName = "freeplay"
				if PlayField.play_manager.play_mode == 0:
					next_menu = "story_menu"
				await unpause()
				Tools.switch_scene(load("res://raven/menu/%s.tscn" % next_menu))

func _reload_list(items_to_use: Array[String] = []) -> void:
	if items_to_use.size() == 0: items_to_use = default_list
	while items.get_child_count() != 0:
		items.get_child(0).queue_free()

	items.modulate.a = 0.0

	var viewport_size: Vector2 = get_viewport().size
	for i: int in items_to_use.size():
		var new_item: Alphabet = Alphabet.new()
		new_item.text = items_to_use[i]
		new_item.alignment = 1
		new_item.position.x = ((viewport_size.x - new_item.size.x) * 0.5) - 15
		new_item.position.y = (viewport_size.y - new_item.size.y) * 0.5
		new_item.position.y += (120 * i) - 180
		new_item.modulate.a = 0.4
		items.add_child(new_item)

	create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD) \
	.tween_property(items, "modulate:a", 1.0, 0.5)

	selected = 0
	update_selection()

func update_selection(new: int = 0) -> void:
	selected = wrapi(selected + new, 0, current_list.size())
	if new != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)

	if visi_tween != null: visi_tween.kill()
	visi_tween = create_tween().set_ease(Tween.EASE_OUT_IN)
	visi_tween.set_parallel(true)

	for i: int in items.get_child_count():
		var item: Alphabet = items.get_child(i) as Alphabet
		visi_tween.tween_property(item, "modulate:a", 1.0 if i == selected else 0.4, 0.1)
		item.item_id = i - selected

func unpause() -> void:
	SoundBoard.stop_tracks()
	if get_tree() != null:
		if exit_callback.is_valid(): exit_callback.call()
		await RenderingServer.frame_post_draw
		get_tree().paused = false

func reload_play_info() -> void:
	var info_stuff: String = tr("pause_deaths") % [ PlayField.death_count ]
	info_stuff += "\n" + tr("pause_practice") % [tr("value_on") if Settings.practice else tr("value_off")]
	info_stuff += "\n" + tr("pause_autoplay") % [tr("value_on") if Settings.autoplay else tr("value_off")]
	play_info.text = info_stuff
