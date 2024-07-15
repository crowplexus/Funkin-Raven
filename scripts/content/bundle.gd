extends Resource
## Bundles are collections of lists with level data[br]
## and song data that is going to be used for providing content to the game.
class_name Bundle

## Bundle Name, which is used as an indentifier.
@export var name: StringName
## Level List, containing level data (name, characters, etc).
@export var level_list: Array[LevelItem] = []
## Song List, contains songs that only show up in Freeplay.
@export var song_list: Array[SongItem] = []

func get_all_songs() -> Array[SongItem]:
	var songs: Array[SongItem] = []
	songs.append_array(get_level_songs())
	songs.append_array(get_song_list())
	return songs

## Returns an array with songs from levels[br]
## Extracted from the [code]level_list[/code] value.
func get_level_songs() -> Array[SongItem]:
	var songs: Array[SongItem] = []
	for level: LevelItem in level_list:
		for song: SongItem in level.song_list:
			if not songs.has(song):
				songs.append(song)
	return songs

## Returns an array with song items[br]
## Extracted from the [code]song_list[/code] value.
func get_song_list() -> Array[SongItem]:
	var songs: Array[SongItem] = []
	for song: SongItem in song_list:
		if not songs.has(song):
			songs.append(song)
	return songs
