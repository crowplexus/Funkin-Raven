extends CanvasLayer

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

func _ready():
	current_list = default_list
	bg.modulate.a = 0.0
	
	var pause_stream: AudioStream = load("res://assets/audio/bgm/breakfast.ogg") as AudioStream
	SoundBoard.play_track(pause_stream, true, 0.01, randf_range(0.0, pause_stream.get_length() * 0.5))
	
	level_info.text = "%s\n%s\n" % [
		tr("pause_songinfo") % PlayField.song_data.name,
		tr("pause_diffinfo") % tr(PlayManager.difficulty.to_lower()).to_upper(),
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

func _process(_delta: float):
	if SoundBoard.bg_tracks.volume_db < linear_to_db(0.5):
		SoundBoard.bg_tracks.volume_db += 0.01

func _unhandled_key_input(_e :InputEvent):
	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	if ud != 0: update_selection(ud)
	
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
				add_child(Tools.get_options_window(func():
					if OptionsBar.will_restart_gameplay:
						PlayField.play_manager.reset()
						OptionsBar.will_restart_gameplay = false
						$"../".process_mode = Node.PROCESS_MODE_DISABLED
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
				Tools.switch_scene(load("res://raven/game/menus/%s.tscn" % next_menu))

func _reload_list(items_to_use: Array[String] = []):
	if items_to_use.size() == 0: items_to_use = default_list
	while items.get_child_count() != 0:
		items.get_child(0).queue_free()
	
	for i in items_to_use.size():
		var new_item: Alphabet = Alphabet.new()
		new_item.spacing.y = 120
		new_item.is_menu_item = true
		new_item.item_id = i
		new_item.text = items_to_use[i]
		items.add_child(new_item)
	
	selected = 0
	update_selection()

func update_selection(new: int = 0):
	selected = wrapi(selected + new, 0, current_list.size())
	if new != 0: SoundBoard.play_sfx(load("res://assets/audio/sfx/menu/scrollMenu.ogg"))
	for i in items.get_child_count():
		var item: Alphabet = items.get_child(i) as Alphabet
		item.modulate.a = 0.6 if i != selected else 1.0
		item.item_id = i - selected

func unpause():
	SoundBoard.stop_tracks()
	if get_tree() != null:
		if exit_callback.is_valid(): exit_callback.call()
		await RenderingServer.frame_post_draw
		get_tree().paused = false

func reload_play_info():
	var info_stuff: String = tr("pause_deaths") % [ PlayField.death_count ]
	info_stuff += "\n" + tr("pause_practice") % [tr("value_on") if Settings.practice else tr("value_off")]
	info_stuff += "\n" + tr("pause_autoplay") % [tr("value_on") if Settings.autoplay else tr("value_off")]
	play_info.text = info_stuff
