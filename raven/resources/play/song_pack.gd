class_name SongPack extends Resource

@export var songs: Array[FreeplaySong] = []
# Story Menu Characters
@export var chars: Array[String] = ["", "gf", "bf"]
@export var difficulties: Array[String] = FreeplaySong.DEFAULT_DIFFICULTIES
@export var tagline: String = "My Story Week"
@export var image: Texture2D = preload("res://assets/images/menus/story/weeks/week1.png")
@export var locked: bool = false

func _ready():
	for i: FreeplaySong in songs:
		# bind song diffs to the week difficulties
		i.difficulties = difficulties
