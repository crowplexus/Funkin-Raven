extends Resource
## Resource containing data for making a song item[br]
## used mainly in freeplay.
class_name SongItem

## Contains a default difficulties list.
## used when none were specified by the user, check [code]SongItem[/code]'s script for details.
const DEFAULT_DIFFICULTY_SET: Array[Dictionary] = [
	{ "display_name": "Easy", "file": "easy",			"variation": "" },
	{ "display_name": "Normal", "file": "normal",			"variation": "" },
	{ "display_name": "Hard", "file": "hard",			"variation": "" },
	{ "display_name": "Erect", "file": "erect",			"variation": "erect" },
	{
		"display_name": "Nightmare",
		"target": "nightmare", # optional, difficulty to target from the file
		"file": "erect", # the actual file to try and load the difficulty from
		"variation": "erect", # the song's "variation" which we use to load files, particularly audio
	},
]

## Self-explanatory.
@export var display_name: StringName = "Test"
## Folder for which chart to load when selecting the song item.
@export var folder_name: StringName = "test"
## Contains difficulties and (potentially) variations
@export var difficulties: Array[Dictionary] = SongItem.DEFAULT_DIFFICULTY_SET
