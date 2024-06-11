extends Resource
## Contains Information about the song itself,
## such as display name, credits, characters, background, etc...
class_name SongInfo

## This is the default rating used in songs
## displayed if a difficulty is missing
## on the [code]evel[/code] dictionary
const DEFAULT_STAR_COUNT: int = -1

## Display Name for the song.
@export var name: StringName = "???"
## Folder Name for the song, usually provided when loading the chart.
@export var folder: StringName = "test"
## Difficulty Name for the song, usually provided when loading the chart.[br]
## [code]file is which *data* file to load in the file system[/code][br]
## [code]target[/code] is which difficulty within the data file to load[br]
## [code]variation[/code] is a suffix for audio files to load before playing the song.
@export var difficulty: Dictionary = {
	"file": "normal",
	"variation": "",
}
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
# Contains difficulties present in this chart.
#@export var difficulties: Array[StringName] = []
## String containing a background's name, usually loads a scene[br]
## However it can load an image if the scene wasn't found[br][br]
## If it fails to load the scene or image, nothing will be loaded.
@export var background: StringName = ""
## Contains names for characters that appear in the song.
@export var characters: PackedStringArray = []


func _to_string() -> String:
	var str_info: String = "Name: %s" % name
	# Credits
	if not credits.is_empty(): str_info += "\n	Credits: %s" % credits
	if not stars.is_empty(): str_info += "\n	Stars: %s" % stars
	#if not difficulties.is_empty(): str_info += "\n	Difficulties: %s" % str(difficulties)
	if not characters.is_empty(): str_info += "\n	Characters: %s" % characters
	if not background.is_empty(): str_info += "\n	Background: %s" % background

	return str_info
