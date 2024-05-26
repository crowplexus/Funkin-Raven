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

## Makes a list containing all the songs
## from your packs, freeplay songs, and user folder.
func make_song_list() -> Array[FreeplaySong]:
	var songs: Array[FreeplaySong] = []
	if show_packs_in_freeplay:
		for i: SongPack in song_packs:
			songs.append_array(i.songs)
	songs.append_array(freeplay_songs)
	if show_user_songs_in_freeplay:
		var user_songs: Array[FreeplaySong] = FreeplaySong.from_user_folder()
		songs.append_array(user_songs)
	return songs

## Makes a list of categories, storing your
## Pack Songs, Freeplay Songs, User Folder Songs
func make_category_list() -> Dictionary:
	var categories: Dictionary = {}
	categories["Base"] = []
	if show_packs_in_freeplay:
		for i: SongPack in song_packs:
			categories["Base"].append_array(i.songs)
	categories["Uncategorized"] = freeplay_songs
	if show_user_songs_in_freeplay:
		categories["User Songs"] = FreeplaySong.from_user_folder()
	return categories
