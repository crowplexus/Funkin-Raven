extends Resource
## Contains Information about the song itself,
## such as display name, credits, characters, background, etc...
class_name SongInfo

## This is the default rating used in songs
## displayed if a difficulty is missing
## on the [code]evel[/code] dictionary
const DEFAULT_STAR_COUNT: int = -1
## Contains a default difficulties list.
## used when none were specified by the user.
const DEFAULT_DIFFICULTY_SET: Array[StringName] = ["easy", "normal", "hard"]

## Display Name for the song.
@export var name: StringName = "???"
## Folder Name for the song, usually provided when loading the chart.
@export var folder: StringName = "test"
## Dictionary with song credits, such as[br]
## the composer of the song[br]
## who mapped it, etc...
@export var credits: Dictionary = {
	"composer": "???",
	"charter": "???",
}
## Contains an integer representing how hard a
## song's mapping is, organized by difficulty.
@export var stars: Dictionary = {}
## Contains difficulties present in this chart.
@export var difficulties: Array[StringName] = []
## String containing a background's name, usually loads a scene[br]
## However it can load an image if the scene wasn't found[br][br]
## If it fails to load the scene or image, nothing will be loaded.
@export var background: StringName = ""


func _to_string() -> String:
	var str_info: String = "Name: %s" % name
	# Credits
	if not credits.is_empty(): str_info += "\n	Credits: %s" % credits
	if not stars.is_empty(): str_info += "\n	Stars: %s" % stars
	if not difficulties.is_empty(): str_info += "\n	Difficulties: %s" % str(difficulties)
	#if not characters.is_empty(): str_info += "\n	Characters: %s" % characters
	if not background.is_empty(): str_info += "\n	Background: %s" % background

	return str_info
