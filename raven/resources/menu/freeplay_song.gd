class_name FreeplaySong extends Resource

const DEFAULT_DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]

@export var name: String = "Unknown"
@export var folder: String = "unknown"
@export var icon: Texture2D
@export var color: Color = Color.DIM_GRAY
@export var difficulties: Array[String] = FreeplaySong.DEFAULT_DIFFICULTIES

func _to_string() -> String:
	return "{ Name: %s, Folder: %s, Difficulties: %s }" % [ name, folder, difficulties ]

static func from_user_folder() -> Array[FreeplaySong]:
	var user_folder: String = "user://songs"
	var list: Array[FreeplaySong] = []

	for i: String in DirAccess.get_directories_at(user_folder):
		var song: FreeplaySong = FreeplaySong.new()

		# load custom difficulties
		var diffs: Array[String] = []
		for j: String in DirAccess.get_files_at("%s/%s/charts/" % [ user_folder, i] ):
			if not j.begins_with("_") and j.get_extension() == "json":
				diffs.append(j.replace(".json", ""))

		song.name = i
		if diffs.size() != 0 and song.difficulties != diffs:
			song.difficulties = diffs
		song.folder = i
		list.append(song)

	return list
