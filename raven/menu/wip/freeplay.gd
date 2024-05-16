# freeplay rewrite but like awesome
extends Menu2D

@onready var song_group: Control = $"ui/songs"
@onready var icon_group: Control = $"ui/icons"
@export  var data_to_use: SongDatabase

var categories: Dictionary = {}
var song_list: Array[FreeplaySong] = []
var category: StringName = ""

func _ready() -> void:
	categories = data_to_use.make_category_list()
	create_items()

func create_items() -> void:
	while song_group.get_child_count() != 0:
		var song_alpha = song_group.get_child(0)
		song_group.remove_child(song_alpha)
		song_group.queue_free()

	while icon_group.get_child_count() != 0:
		var song_icon  = icon_group.get_child(0)
		icon_group.remove_child(song_icon)
		song_icon.queue_free()

	var array_to_iterate: Array = categories.keys() if category=="" else song_list

	for i: int in array_to_iterate.size():
		var title: StringName = array_to_iterate[i]
		if category != "": title = array_to_iterate[i].name
		var song_thing: Alphabet = Alphabet.new()
		song_thing.is_menu_item = true
		song_thing.text = title
		song_thing.spacing.y = 140
		song_thing.item_id = i
		song_thing.item_offset.y -= 250
		song_group.add_child(song_thing)

		if category != "":
			var icon_thing: Sprite2D = Sprite2D.new()
			if song_list[i].icon != null:
				icon_thing.texture = song_list[i].icon
			icon_thing.hframes = 2
			icon_group.add_child(icon_thing)
