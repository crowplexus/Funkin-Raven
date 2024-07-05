extends Resource
## Contains Information about the song itself,
## such as display name, credits, characters, background, etc...
class_name SongInfo

## This is the default rating used in songs
## displayed if a difficulty is missing
## on the [code]evel[/code] dictionary
const DEFAULT_STAR_COUNT: int = -1

## Default Notefield configuration.
const DEFAULT_NOTEFIELD_CONFIG: Array[Dictionary] = [
	{
		"name": "player1_notefield", # custom name
		"spot": 1.0, # right
		"characters": ["player1"], # node names e.g: player1, player2
		"key_count": 4,
		"visible": true,
		"scale": Vector2.ONE,
	},
	{
		"name": "player2_notefield",
		"spot": 0.0, # left
		"characters": ["player2"],
		"key_count": 4,
		"visible": true,
		"scale": Vector2.ONE,
	},
	#{
	#	"name": "3",
	#	"spot": 0.5, # center
	#	"characters": ["player3"],
	#	"key_count": 4,
	#	"visible": true,
	#	"scale": Vector2.ONE,
	#},
]

## Display Name for the song.
@export var name: StringName = "<REPLACE>"
## Folder Name for the song, usually provided when loading the chart.
var folder: StringName = "test"
## Song UI Style, changes certain elements in the UI, for example judgments and combo
@export var ui_skin: UISkin = Globals.DEFAULT_SKIN
## Difficulty Name for the song, usually provided when loading the chart.[br]
## [code]file is which *data* file to load in the file system[/code][br]
## [code]target[/code] is which difficulty within the data file to load[br]
## [code]variation[/code] is a suffix for audio files to load before playing the song.
var difficulty: Dictionary = {
	"display_name": "Normal",
	"file": "normal",
	"variation": "",
}
## Notefield configuration for gameplay purposes.
@export var notefields: Array[Dictionary] = DEFAULT_NOTEFIELD_CONFIG
## Dictionary with song credits, such as[br]
## the artist who made the song[br]
## who mapped it, etc...
@export var credits: Dictionary = { "artist": "???", "charter": "???", }
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
## Audio stream for the instrumental that will be played in-game.
@export var instrumental: AudioStream
## Contains audio streams with vocal files.
@export var vocals: Array[AudioStream] = []


func configure_notefield(nf: NoteField, config: Dictionary) -> void:
	if "name" in config: nf.name = config.name
	if "spot" in config: nf.playfield_spot = config.spot
	if "visible" in config: nf.visible = config.visible
	if "key_count" in config: nf.key_count = config.key_count
	if "scale" in config:
		if config.scale is Vector2: nf.scale = config.scale
		elif config.scale is float: nf.scale = Vector2(config.scale, config.scale)


static func parse_json_notefield_conf(config: Dictionary, id: int) -> Dictionary:
	var nfg: Dictionary = SongInfo.DEFAULT_NOTEFIELD_CONFIG[id].duplicate()
	if "name" in config: nfg.name = config.name
	if "spot" in config: nfg.spot = config.spot
	if "characters" in config: nfg.characters = config.characters
	if "keyCount" in config: nfg.key_count = int(config["keyCount"])
	if "visible" in config: nfg.visible = config.visible
	if "scale" in config:
		if config.scale is float:
			nfg.scale = Vector2(config.scale, config.scale)
		elif config.scale is Array:
			nfg.scale = Vector2(config.scale[0], config.scale[1])
	return nfg


func _to_string() -> String:
	var str_info: String = "Name: %s" % name
	# Credits
	if not credits.is_empty(): str_info += "\n	Credits: %s" % credits
	if not stars.is_empty(): str_info += "\n	Stars: %s" % stars
	#if not difficulties.is_empty(): str_info += "\n	Difficulties: %s" % str(difficulties)
	if not characters.is_empty(): str_info += "\n	Characters: %s" % characters
	if not background.is_empty(): str_info += "\n	Background: %s" % background

	return str_info
