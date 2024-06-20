extends Resource
class_name LevelItem

## Level Name, displayed in the story menu.
@export var level_name: String = "My Level"
## Level Background, shown in the story menu.
@export var background: Texture2D
## Texture displayed in the story menu to represent the level.
@export var label_texture: Texture2D
## Song List attached to this level.
@export var song_list: Array[SongItem] = []
