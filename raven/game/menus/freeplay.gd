extends Menu2D

const GAME_PATH: String = "res://raven/game/gameplay.tscn"

@onready var song_group: Control = $song_group
@onready var icon_group: Control = $icon_group

@onready var score_text: Label = $score_text
@onready var diff_text: Label = $score_text/diff_text
@export var song_data: SongDatabase = preload("res://raven/resources/play/default_songs.tres")

var song_list: Array[FreeplaySong] = []

var _display_stats: bool = false
var _selected: bool = false
var _bg_tween: Tween

func _ready():
	if not SoundBoard.bg_tracks.playing:
		SoundBoard.play_track(load("res://assets/audio/bgm/freakyMenu.ogg"))
	
	song_list = song_data.make_freeplay_list()
	
	for i in song_list.size():
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
	total_selectors = song_group.get_child_count()
	
	alternative = song_list[selected].difficulties.find(
		song_list[selected].difficulties.back())
	
	update_selection()
	update_alternative()

func _process(_delta: float):
	for i in song_group.get_child_count():
		var item: = song_group.get_child(i) as Alphabet
		var icon: = icon_group.get_child(i) as Sprite2D
		
		icon.position = Vector2(
			(item.position.x + item.end_position.x) + 80,
			(item.position.y + item.end_position.y + 30)
		)
		icon.modulate.a = item.modulate.a

func update_selection(new: int = 0):
	if total_selectors < 2: return
	super(new)

	if new != 0: SoundBoard.play_sfx(SCROLL_SOUND)
	for i in song_group.get_child_count():
		var let: Alphabet = song_group.get_child(i) as Alphabet
		let.modulate.a = 1.0 if i == selected else 0.6
		let.item_id = i - selected
	
	if _bg_tween != null: _bg_tween.stop()
	_bg_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_bg_tween.tween_property($bg, "modulate", song_list[selected].color, 0.5)
	
	total_alternatives = song_list[selected].difficulties.size()
	if alternative >= total_alternatives: alternative = total_alternatives - 1
	update_alternative()

func update_alternative(new: int = 0):
	super(new)
	var text_str: String = "< %s >" if total_alternatives > 1 else "%s"
	if new != 0 and total_alternatives > 1: SoundBoard.play_sfx(SCROLL_SOUND)
	diff_text.text = "\"%s\"\n" % song_list[selected].name
	diff_text.text += text_str % tr(song_list[selected].difficulties[alternative].to_lower())
	update_score_display()

func _unhandled_key_input(e: InputEvent):
	if _selected: return
	super(e)
	
	if e.keycode == KEY_CTRL:
		if e.is_pressed():
			_display_stats = not _display_stats
			update_score_display()
	if Input.is_key_label_pressed(KEY_CTRL) and Input.is_key_label_pressed(KEY_O):
		self.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(Tools.get_options_window())
	
	if e.is_action_pressed("ui_cancel"):
		Tools.switch_scene(load("res://raven/game/menus/main_menu.tscn"))
		_selected = true

	if e.is_action_pressed("ui_accept"):
		var diff: String = song_list[selected].difficulties[alternative]
		var file: String = PlayManager.find_file(song_list[selected].folder, diff)
		if file != null:
			SoundBoard.stop_tracks()
			
			if PlayField.play_manager == null:
				PlayField.play_manager = PlayManager.new(1, -1)
			else:
				PlayField.play_manager.play_mode = 1
				PlayField.play_manager.current_week = -1
			
			PlayManager.set_song(song_list[selected], diff)
			Tools.switch_scene(load(GAME_PATH))

func update_score_display():
	var song: = song_list[selected]
	var diff: String = song.difficulties[alternative]
	var perf: Dictionary = Highscore.get_performance_stats(song.name, diff)
	
	var base: String = tr("freeplay_top") + ":%s" % perf.score
	if _display_stats:
		base += "\n"+tr("info_accuracy")+":%s" % [str(perf.accuracy) + "%"]
		base += "\n"+tr("info_misses")+":%s" % [str(perf.misses)]
		base += "\n"+tr("info_evaluation")+":"+perf.evaluation
	else:
		base += "\n[%s]" % tr("freeplay_ctrl")
	score_text.text = base
