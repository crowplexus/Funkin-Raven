extends Node2D

@onready var song_list: VBoxContainer = $"ui/song_container"
@onready var diff_label: Label = $"ui/difficulty_text"

@export var item_idle_opacity: float = 0.6
@export var item_selected_opacity: float = 1.0
@export var bundle: Bundle
var songs: Array[SongItem] = []

var current_item: CanvasItem
var current_difficulty: Dictionary
var current_selection: int = 1
var current_alternative: int = 1
var _transitioning: bool = false
var music_fade_twn: Tween

func _ready() -> void:
	play_bgm_check(Globals.MENU_MUSIC)
	$"ui/song_container/random".modulate.a = item_idle_opacity
	songs = bundle.get_all_songs()
	generate_songs()


func _unhandled_input(e: InputEvent) -> void:
	# prevents a bug with moving the mouse which would change selections nonstop
	if e is InputEventMouseMotion:
		return

	if _transitioning == true:
		return

	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	var lr: int = int(Input.get_axis("ui_left", "ui_right"))
	if e is InputEventMouse and e.shift_pressed:
		lr = ud

	if ud: update_selection(ud)
	if lr: update_alternative(lr)

	if Input.is_action_just_pressed("ui_cancel"):
		_transitioning = true
		# stupid check to stop random bgm when its playing
		if SoundBoard.current_bgm != Globals.MENU_MUSIC.resource_path.get_file().get_basename():
			play_bgm_check(Globals.MENU_MUSIC, true)
		SoundBoard.play_sfx(Globals.MENU_CANCEL_SFX)
		Globals.change_scene(load("res://scenes/menu/main_menu.tscn"))

	if Input.is_action_just_pressed("ui_accept"):
		_transitioning = true
		if current_selection == 0:
			current_selection = randi_range(1, song_list.get_child_count())
			update_selection()

		SoundBoard.play_sfx(Globals.MENU_CONFIRM_SFX)
		await get_tree().create_timer(1.0).timeout

		SoundBoard.stop_bgm()
		Chart.global = Chart.request(songs[current_selection - 1].folder_name, current_difficulty)
		if Chart.global.song_info.name == "???":
			Chart.global.song_info.name = songs[current_selection - 1].display_name
		Globals.change_scene(load("res://scenes/gameplay/gameplay.tscn"))


func update_selection(new_sel: int = 0) -> void:
	if is_instance_valid(current_item):
		current_item.modulate.a = item_idle_opacity
	current_selection = wrapi(current_selection + new_sel, 0, song_list.get_child_count())
	current_item = song_list.get_child(current_selection)
	current_item.modulate.a = item_selected_opacity

	# i have to tell my brain to stop hardcoding @crowplexus
	var menu_bgm_name: = Globals.MENU_MUSIC.resource_path.get_file().get_basename()
	var random_bgm_name: = Globals.RANDOM_MUSIC.resource_path.get_file().get_basename()

	match SoundBoard.current_bgm:
		menu_bgm_name when current_selection == 0:
			play_bgm_check(Globals.RANDOM_MUSIC, true, true)
		random_bgm_name when current_selection != 0:
			play_bgm_check(Globals.MENU_MUSIC, true, true)
	update_alternative()


func update_alternative(new_alt: int = 0) -> void:
	current_alternative = wrapi(current_alternative + new_alt, 0, songs[current_selection - 1].difficulties.size())
	current_difficulty = songs[current_selection - 1].difficulties[current_alternative]
	diff_label.text = current_difficulty.display_name
	if current_difficulty.size() > 1:
		diff_label.text = "< %s > " % current_difficulty.display_name



func generate_songs() -> void:
	for item: Control in song_list.get_children():
		if item.get_index() == 0:
			continue
		item.free()

	for song: SongItem in songs:
		var new_item: Label = song_list.get_child(0).duplicate()
		new_item.name = song.display_name.to_snake_case()
		new_item.modulate.a = item_idle_opacity
		new_item.text = song.display_name
		song_list.add_child(new_item)

	update_selection()
	update_alternative()


func play_bgm_check(song: AudioStream, skip_check: bool = false, fade: bool = false) -> void:
	if not SoundBoard.is_bgm_playing() or skip_check:
		SoundBoard.play_bgm(song, 0.01 if fade else 0.7)
		if fade: SoundBoard.fade_bgm(0.01, 0.7, 1.0)
