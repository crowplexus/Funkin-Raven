class_name Modchart extends Node
static func create(path: String, new_song: FreeplaySong, new_game: Variant):
	var modchart: = Modchart.new()
	modchart.set_script(load(path))
	modchart.name = new_song.name + "_Modchart"
	modchart.song = new_song
	modchart.game = new_game
	return modchart
# Variables #
var song: FreeplaySong
var game: Variant
# Functions #
# func assign_notefield():
