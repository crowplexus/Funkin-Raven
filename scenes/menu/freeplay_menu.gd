extends Node2D

@onready var bg: Sprite2D = $"background"
@onready var score_label: Label = $"ui/score_text"
@onready var diff_label: Label = $"ui/score_text/difficulty_text"
@onready var playlist_label: Label = $"ui/playlist_text"
@onready var song_container: Control = $"ui/song_container"

@export var item_idle_opacity: float = 0.6
@export var item_selected_opacity: float = 1.0
@export var bundle: Bundle

var songs: Array[SongItem] = []
var personal_playlist: Array[SongItem] = []
var all_difficulties: Array[Dictionary] = []
var options: Array[CanvasItem] = []

var current_item: CanvasItem
var current_difficulty: Dictionary
static var current_selection: int = 1
var current_alternative: int = 1
var music_fade_twn: Tween
var playlist_twn: Tween
var current_top: Tally

var _random_icon: Sprite2D
var random_icon_origin: Vector2 = Vector2.ZERO
var _time_wasted: float = 0.0

func _ready() -> void:
	playlist_label.modulate.a = 0.0
	play_bgm_check(Globals.MENU_MUSIC)
	$"ui/song_container/random".modulate.a = item_idle_opacity
	if bundle: songs = bundle.get_all_songs()
	generate_songs()

func _process(delta: float) -> void:
	if _random_icon:
		var move_random_icon: bool = current_item.name == "random"
		if not move_random_icon and _random_icon.position.y != random_icon_origin.y:
			_random_icon.position = random_icon_origin
		if move_random_icon:
			_time_wasted += delta
			float_random_icon()

func float_random_icon() -> void:
	var floaty: float = (sin(_time_wasted * PI) * 5.5) - 5.0
	_random_icon.position.y = random_icon_origin.y + floaty

func _unhandled_input(e: InputEvent) -> void:
	# prevents a bug with moving the mouse which would change selections nonstop
	if e is InputEventMouseMotion:
		return

	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	var lr: int = int(Input.get_axis("ui_left", "ui_right"))
	if e is InputEventMouse and e.shift_pressed:
		lr = ud

	if ud: update_selection(ud)
	if lr: update_alternative(lr)

	if Input.is_key_label_pressed(KEY_CTRL) and current_selection != 0:
		var song: = songs[current_selection - 1]
		song.difficulty = current_difficulty
		if not personal_playlist.has(song):
			current_item.modulate = Color.TURQUOISE
			personal_playlist.append(song)
		else:
			current_item.modulate = Color.WHITE
			personal_playlist.erase(song)
		playlist_label.text = "[PLAYLIST]\n"
		for stored_song: SongItem in personal_playlist:
			playlist_label.text += stored_song.display_name
			playlist_label.text += " [%s]" % stored_song.get_difficulty_name()
			if personal_playlist.find(stored_song) != personal_playlist.size():
				playlist_label.text += "\n"

		var v: float = 1.0 if not personal_playlist.is_empty() else 0.0
		if playlist_label.modulate.a != v:
			if playlist_twn:
				playlist_twn.kill()
			playlist_twn = create_tween().set_ease(Tween.EASE_IN)
			playlist_twn.tween_property(playlist_label, "modulate:a", v, 0.5)

	if Input.is_action_just_pressed("ui_cancel"):
		Globals.set_node_inputs(self, false)
		# stupid check to stop random bgm when its playing
		#if SoundBoard.current_bgm != Globals.MENU_MUSIC.resource_path.get_file().get_basename():
		#	play_bgm_check(Globals.MENU_MUSIC, true)
		SoundBoard.play_sfx(Globals.MENU_CANCEL_SFX)
		Globals.change_scene(load("res://scenes/menu/main_menu.tscn"))

	if Input.is_action_just_pressed("ui_accept"):
		Globals.set_node_inputs(self, false)
		if current_item.name == "random":
			current_selection = find_random_song()
			update_selection()

		SoundBoard.stop_bgm()
		if not personal_playlist.is_empty():
			Gameplay.game_mode = Gameplay.GameMode.PLAYLIST
			Gameplay.play_list = personal_playlist.duplicate()
			Gameplay.play_list_pos = 0
			Chart.global = Chart.request(personal_playlist[0].folder_name, personal_playlist[0].difficulty)
		else:
			Chart.global = Chart.request(songs[current_selection - 1].folder_name, current_difficulty)
			Gameplay.game_mode = Gameplay.GameMode.FREEPLAY
			if Chart.global.song_info.name == "<REPLACE>":
				Chart.global.song_info.name = songs[current_selection - 1].display_name
			songs[current_selection - 1].difficulty = current_difficulty

		# TRANSITION TO GAMEPLAY #
		transition_out()
		SoundBoard.play_sfx(Globals.MENU_CONFIRM_SFX)
		if Preferences.flashing:
			Globals.begin_flicker(current_item, 1.0, 0.06, false)
		await get_tree().create_timer(1.0).timeout
		Globals.change_scene(load("res://scenes/gameplay/gameplay.tscn"))

func update_selection(new_sel: int = 0) -> void:
	if options.is_empty():
		return

	if current_item: current_item.modulate.a = item_idle_opacity
	current_selection = wrapi(current_selection + new_sel, 0, options.size())
	if new_sel != 0: SoundBoard.play_sfx(Globals.MENU_SCROLL_SFX)
	current_item = options[current_selection]
	current_item.modulate.a = item_selected_opacity

	for thingy: CanvasItem in options:
		if thingy is Alphabet and thingy.visible:
			var i: int = options.find(thingy)
			thingy.menu_target = i - current_selection

	reset_menu_song()
	update_alternative()

func reset_menu_song() -> void:
	if not Globals.RANDOM_MUSIC:
		return
	# i have to tell my brain to stop hardcoding @crowplexus
	var menu_bgm_name: = Globals.MENU_MUSIC.resource_path.get_file().get_basename()
	var random_bgm_name: = Globals.RANDOM_MUSIC.resource_path.get_file().get_basename()
	match SoundBoard.current_bgm:
		menu_bgm_name when current_item.name == "random":
			play_bgm_check(Globals.RANDOM_MUSIC, true, true)
		random_bgm_name when current_item.name != "random":
			play_bgm_check(Globals.MENU_MUSIC, true, true)

func find_random_song() -> int:
	var random_song: SongItem = songs.pick_random()
	var song_id: int = songs.find(random_song)
	# TODO: make this more random i guess idk?
	if song_id == 0: random_song = songs.pick_random()
	if random_song.difficulties.has(current_difficulty):
		random_song = songs.pick_random()
	return songs.find(random_song)

func update_alternative(new_alt: int = 0) -> void:
	if options.is_empty():
		return
	var diffs: Array[Dictionary] = all_difficulties
	if current_selection > 0:
		diffs = songs[current_selection - 1].difficulties
	current_alternative = wrapi(current_alternative + new_alt, 0, diffs.size())
	current_difficulty = diffs[current_alternative]

	if new_alt != 0: SoundBoard.play_sfx(Globals.MENU_SCROLL_SFX)
	if diffs.size() > 1:
		diff_label.text = "< %s > " % current_difficulty.display_name
	else:
		diff_label.text = current_difficulty.display_name
	update_highscore()

func update_highscore() -> void:
	var song: = songs[current_selection - 1]
	# this sucks, i know it sucks, it's the best way i found
	if not Highscore.check_signature(Highscore.cached_hi):
		Highscore.cached_hi = Highscore.open()
	current_top = Highscore.get_hi(Highscore.cached_hi, song.folder_name, current_difficulty)
	if is_instance_valid(current_top):
		score_label.text = "TOP SCORE: " + str(current_top.score).pad_zeros(6)
		score_label.text += "\nAccuracy: %s%%" % snappedf(current_top.accuracy, 0.01)
	else:
		score_label.text = "TOP SCORE: 000000\nAccuracy: N/A"

func transition_out() -> void:
	for i: Control in song_container.get_children():
		if i != current_item:
			i.set_process(false)
			var vpx: float = get_viewport_rect().size.x
			create_tween().set_ease(Tween.EASE_OUT).bind_node(i) \
			.tween_property(i, "position:x", i.position.x - vpx, 0.4)

func generate_songs() -> void:
	if not bundle or songs.is_empty():
		song_container.get_child(0).hide()
		score_label.visible = false
		var error_notice: Alphabet = Alphabet.new()
		error_notice.size = get_viewport_rect().size
		error_notice.horizontal_alignment = 1
		error_notice.vertical_alignment = 1
		error_notice.text = "No songs found"
		add_child(error_notice)
		return

	options.clear()
	all_difficulties.clear()
	for item: Control in song_container.get_children():
		if item.name == "random":
			item.visible = songs.size() > 1
			if item.visible: options.append(item)
			continue
		item.free()

	var ouch: int = 0
	for song: SongItem in songs:
		var new_item: Alphabet = song_container.get_child(0).duplicate()
		#new_item.name = song.display_name.to_snake_case()
		new_item.position.y += new_item.y_per_roll * ouch
		new_item.modulate.a = item_idle_opacity
		new_item.text = song.display_name
		new_item.menu_target = ouch + 1
		new_item.visible = true
		song_container.add_child(new_item)

		for diff: Dictionary in song.difficulties:
			if not all_difficulties.has(diff):
				all_difficulties.append(diff)

		var icon: Sprite2D = Sprite2D.new()
		icon.name = "icon"
		if song.icon and song.icon.texture:
			icon.texture = song.icon.texture
			icon.texture_filter = song.icon.filter
			icon.hframes = song.icon.hframes
			icon.vframes = song.icon.vframes
			icon.scale = song.icon.scale
		icon.global_position.x = new_item.glyphs_pos.x + 60
		new_item.add_child(icon)
		options.append(new_item)
		ouch += 1

	if not song_container.get_child(0).has_node("icon"):
		var random_alpha: = song_container.get_child(0)
		_random_icon = $"random_icon"
		_random_icon.reparent(random_alpha)
		_random_icon.name = "icon"
		random_icon_origin = _random_icon.position

	if current_selection > options.size():
		current_selection = 1

	update_selection()
	update_alternative()

func play_bgm_check(song: AudioStream, skip_check: bool = false, fade: bool = false) -> void:
	if not SoundBoard.is_bgm_playing() or skip_check:
		SoundBoard.play_bgm(song, 0.01 if fade else 0.7)
		if fade: SoundBoard.fade_bgm(0.01, 0.7, 1.0)
