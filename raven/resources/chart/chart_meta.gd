class_name ChartMeta extends Resource

@export var authors: Array[String] = []
@export var audio_tracks: Array[AudioStream] = []
@export var offset: float = 0.0
@export var skin: UISkin

func get_authors() -> String:
	var temp: String = ""
	for i: int in authors.size():
		temp += authors[i]
	return temp

func get_tracks(id: int = -1) -> Variant:
	if id != -1 and id < audio_tracks.size():
		return audio_tracks[id]
	return audio_tracks
