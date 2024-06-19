extends Node2D

@onready var song_list: VBoxContainer = $"ui/song_container"
@onready var diff_label: Label = $"ui/difficulty_text"

@export var item_idle_opacity: float = 0.6
@export var item_selected_opacity: float = 1.0
@export var songs: Array[SongItem] = []

var current_item: CanvasItem
var current_difficulty: Dictionary
var current_selection: int = 0
var current_alternative: int = 0
var _transitioning: bool = false
var _template_song: Label


func _ready() -> void:
	if not SoundBoard.is_bgm_playing():
		SoundBoard.play_bgm(Globals.MENU_MUSIC, 0.7)
	_template_song = song_list.get_child(0).duplicate()
	song_list.remove_child($"ui/song_container/cool_song")
	generate_songs()


func _unhandled_key_input(_event: InputEvent) -> void:
	if _transitioning == true:
		return

	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	var lr: int = int(Input.get_axis("ui_left", "ui_right"))
	if ud: update_selection(ud)
	if lr: update_alternative(lr)

	if Input.is_key_label_pressed(KEY_O) and not get_tree().paused:
		var ow: Control = Globals.get_options_window()
		#ow.position = get_viewport_rect().size * 0.5
		ow.set_deferred("size", get_viewport_rect().size)
		get_tree().paused = true
		add_child(ow)

	if Input.is_action_just_pressed("ui_accept"):
		SoundBoard.stop_bgm()
		Chart.global = Chart.request(songs[current_selection].folder_name, current_difficulty)
		if Chart.global.song_info.name == "???":
			Chart.global.song_info.name = songs[current_selection].display_name
		Globals.change_scene(load("res://scenes/gameplay/gameplay.tscn"))


func update_selection(new_sel: int = 0) -> void:
	if is_instance_valid(current_item):
		current_item.modulate.a = item_idle_opacity
	current_selection = wrapi(current_selection + new_sel, 0, song_list.get_child_count())
	current_item = song_list.get_child(current_selection)
	current_item.modulate.a = item_selected_opacity


func update_alternative(new_alt: int = 0) -> void:
	current_alternative = wrapi(current_alternative + new_alt, 0, songs[current_selection].difficulties.size())
	current_difficulty = songs[current_selection].difficulties[current_alternative]
	diff_label.text = current_difficulty.display_name
	if current_difficulty.size() > 1:
		diff_label.text = "< %s > " % current_difficulty.display_name



func generate_songs() -> void:
	for item: Control in song_list.get_children():
		item.free()

	for song: SongItem in songs:
		var new_item: Label = _template_song.duplicate()
		new_item.name = song.display_name.to_snake_case()
		new_item.modulate.a = item_idle_opacity
		new_item.text = song.display_name
		song_list.add_child(new_item)

	update_selection()
	update_alternative()
