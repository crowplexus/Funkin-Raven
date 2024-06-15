extends Node2D

@onready var song_list: VBoxContainer = $"song_container"

@export var songs: Array[SongItem] = []

var current_selection: int = 0
var _transitioning: bool = false
var _template_song: Label


func _ready() -> void:
	if not SoundBoard.is_bgm_playing():
		SoundBoard.play_bgm(Globals.MENU_MUSIC, 0.7)
	_template_song = song_list.get_child(0).duplicate()
	song_list.remove_child($"song_container/cool_song")
	generate_songs()


func _unhandled_key_input(_event: InputEvent) -> void:
	if _transitioning == true:
		return

	var axis: int = int(Input.get_axis("ui_up", "ui_down"))
	if axis: update_selection(axis)

	if Input.is_key_label_pressed(KEY_O) and not get_tree().paused:
		var ow: Control = Globals.get_options_window()
		#ow.position = get_viewport_rect().size * 0.5
		ow.set_deferred("size", get_viewport_rect().size)
		get_tree().paused = true
		add_child(ow)

	if Input.is_action_just_pressed("ui_accept"):
		var song: = {
			"file": songs[current_selection].folder_name,
			# 0 Easy, 1 Normal, 2 Hard, 3 Erect, 4 Nightmare
			"diff": SongItem.DEFAULT_DIFFICULTY_SET[2]
		}
		SoundBoard.stop_bgm()
		Chart.global = Chart.request(song.file, song.diff)
		Globals.change_scene(load("res://scenes/gameplay/gameplay.tscn"))


func update_selection(new_sel: int = 0) -> void:
	current_selection = wrapi(current_selection + new_sel, 0, song_list.get_child_count())
	for item: Control in song_list.get_children():
		if item.get_index() == current_selection:
			item.modulate.a = 1.0
		else:
			item.modulate.a = 0.6

func generate_songs() -> void:
	for item: Control in song_list.get_children():
		item.free()

	for song: SongItem in songs:
		var new_item: Label = _template_song.duplicate()
		new_item.name = song.display_name.to_snake_case()
		new_item.text = song.display_name
		song_list.add_child(new_item)

	update_selection()
