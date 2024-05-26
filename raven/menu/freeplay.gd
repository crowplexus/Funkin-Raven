extends Menu2D

const GAME_PATH: PackedScene = preload("res://raven/play/gameplay.tscn")

@onready var song_group: Control = $song_group
@onready var icon_group: Control = $icon_group

@onready var bg: Sprite2D = $"bg"
@onready var loading_funkers: Sprite2D = $"loading"

@onready var score_text: Label = $score_text
@onready var diff_text: Label = $score_text/diff_text
@export var song_data: SongDatabase = preload("res://assets/data/default_songs.tres")

var song_list: Array[FreeplaySong] = []

var _display_stats: bool = false
var _selected: bool = false
var _bg_tween: Tween
var _visi_tween: Tween

var _loading_thread: Thread
var _thread_running_time: float = 0.0
var _is_loading_song: bool = false

func _ready() -> void:
	can_open_options = true
	if not SoundBoard.bg_tracks.playing:
		SoundBoard.play_track(load("res://assets/audio/bgm/freakyMenu.ogg"))

	song_list = song_data.make_song_list()
	_loading_thread = Thread.new()

	for i: int in song_list.size():
		var song_thing: Alphabet = Alphabet.new()
		song_thing.is_menu_item = true
		song_thing.text = song_list[i].name
		song_thing.spacing.y = 140
		song_thing.item_id = i
		song_group.add_child(song_thing)

		var icon_thing: Sprite2D = Sprite2D.new()
		if song_list[i].icon != null:
			icon_thing.texture = song_list[i].icon
		icon_thing.hframes = 2
		icon_group.add_child(icon_thing)
	voptions = song_group.get_children()

	alternative = song_list[selected].difficulties.find(
		song_list[selected].difficulties.back())

	update_selection()
	update_alternative()

func _process(_delta: float) -> void:
	if loading_funkers.modulate.a != 1.0 and _loading_thread.is_alive():
		_thread_running_time += _delta
		if _thread_running_time >= 5:
			show_loading_funkers()

	elif _is_loading_song and not _loading_thread.is_alive():
		_loading_thread.wait_to_finish()
		_is_loading_song = false
		SoundBoard.stop_tracks()
		Tools.switch_scene(GAME_PATH)

	for i: int in song_group.get_child_count():
		var item: = song_group.get_child(i) as Alphabet
		var icon: = icon_group.get_child(i) as Sprite2D

		icon.position = Vector2(
			(item.position.x + item.end_position.x) + 80,
			(item.position.y + item.end_position.y + 30)
		)
		icon.modulate.a = item.modulate.a

func update_selection(new: int = 0) -> void:
	super(new)

	if new != 0: SoundBoard.play_sfx(SCROLL_SOUND)
	if _visi_tween != null: _visi_tween.stop()
	_visi_tween = create_tween().set_ease(Tween.EASE_OUT_IN)
	_visi_tween.set_parallel(true)

	for i: int in song_group.get_child_count():
		var let: Alphabet = song_group.get_child(i) as Alphabet
		_visi_tween.tween_property(let, "modulate:a", 1.0 if i == selected else 0.6, 0.1)
		let.item_id = i - selected

	if _bg_tween != null: _bg_tween.stop()
	_bg_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_bg_tween.tween_property(bg, "modulate", song_list[selected].color, 0.5)

	hoptions = song_list[selected].difficulties
	if alternative >= hoptions.size(): alternative = hoptions.size() - 1
	update_alternative()

func update_alternative(new: int = 0) -> void:
	super(new)
	var text_str: String = "< %s >" if hoptions.size() > 1 else "%s"
	if new != 0 and hoptions.size() > 1: SoundBoard.play_sfx(SCROLL_SOUND)
	diff_text.text = "\"%s\"\n" % song_list[selected].name
	diff_text.text += text_str % tr(song_list[selected].difficulties[alternative].to_lower())
	update_score_display()

func _unhandled_key_input(e: InputEvent) -> void:
	if _selected: return
	super(e)

	if e.keycode == KEY_CTRL:
		if e.is_pressed():
			_display_stats = not _display_stats
			update_score_display()

	if Input.is_action_just_pressed("ui_cancel"):
		Tools.switch_scene(load("res://raven/menu/main_menu.tscn"))
		_selected = true

	if Input.is_action_just_pressed("ui_accept"):
		var diff: String = song_list[selected].difficulties[alternative]
		var file: String = Progression.find_file(song_list[selected].folder, diff)
		if file != null:
			if PlayField.play_manager == null:
				PlayField.play_manager = Progression.new(1, -1)
			else:
				PlayField.play_manager.play_mode = 1
				PlayField.play_manager.current_level = -1

			_loading_thread.start(load_thread_begin)
			create_tween().set_ease(Tween.EASE_IN) \
			.tween_property(bg, "modulate:v", 0.1, 0.8)
			_is_loading_song = true
			_selected = true

func load_thread_begin() -> bool:
	var diff: String = song_list[selected].difficulties[alternative]
	Progression.set_song(song_list[selected], diff)
	return PlayField.chart != null

func show_loading_funkers() -> void:
	create_tween().bind_node(loading_funkers).set_ease(Tween.EASE_IN) \
	.tween_property(loading_funkers, "modulate:a", 1.0, 0.5)

func update_score_display() -> void:
	var song: = song_list[selected]
	var diff: String = song.difficulties[alternative]
	var perf: Dictionary = Highscore.get_performance_stats(song.name, diff)

	var base: String = tr("freeplay_top") + ":%s" % perf.score
	if _display_stats:
		base += "\n"+tr("info_accuracy")+":%s" % [str(perf.accuracy) + "%"]
		base += "\n"+tr("info_misses")+":%s" % [str(perf.misses)]
		base += "\n"+tr("info_grade")+":"+perf.grade
	else:
		base += "\n[%s]" % tr("freeplay_ctrl")
	score_text.text = base
