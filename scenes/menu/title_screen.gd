extends Node2D

@export var songs: Array[SongItem] = []

func _ready() -> void:
	var song: = {
		"file": "darnell",
		# 0 Easy, 1 Normal, 2 Hard, 3 Erect, 4 Nightmare
		"diff": SongItem.DEFAULT_DIFFICULTY_SET[2]
	}
	Chart.global = Chart.request(song.file, song.diff)
	await RenderingServer.frame_post_draw
	get_tree().change_scene_to_packed(load("res://scenes/gameplay/gameplay.tscn"))
