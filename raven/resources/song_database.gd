class_name SongDatabase extends Resource

## List of songs that will appear in the Story Mode Menu.
@export var song_packs: Array[SongPack] = []
## List of songs that will appear in the Freeplay Menu.
@export var freeplay_songs: Array[FreeplaySong] = []
## If songs from all the [code]song_packs[/code]
## should be shown in Freeplay.
@export var show_packs_in_freeplay: bool = true
## If songs from the [code]"user://songs/"[/code] folder
## should be shown in Freeplay.
@export var show_user_songs_in_freeplay: bool = true

func make_freeplay_list() -> Array[FreeplaySong]:
	var songs: Array[FreeplaySong] = []
	
	if show_packs_in_freeplay:
		for i: SongPack in song_packs:
			songs.append_array(i.songs)
	
	songs.append_array(freeplay_songs)
	
	if show_user_songs_in_freeplay:
		var user_songs: Array[FreeplaySong] = FreeplaySong.from_user_folder() 
		songs.append_array(user_songs)
	
	return songs

# doing it later.
#func make_freeplay_categories() -> Dictionary:
#	var categories: Dictionary = {}
#	
#	if show_packs_in_freeplay:
#		for i: SongPack in song_packs:
#			categories[i.tagline] = i.songs
#	
#	categories["Freeplay Songs"] = freeplay_songs
#	
#	if show_user_songs_in_freeplay:
#		var user_songs: Array[FreeplaySong] = FreeplaySong.from_user_folder() 
#		categories["User Songs"] = user_songs
#	
#	return categories
