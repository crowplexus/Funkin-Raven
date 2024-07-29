extends Node2D

func _ready() -> void:
	var p: String = "res://assets/songs/Through the Fire and Flames v3/fire.sm"
	var file: = FileAccess.open(p, FileAccess.READ).get_as_text()
	var sm: = Chart.PARSERS.stepmania.new()
	sm.path = p.get_base_dir()
	sm.data = file
	sm.diff = "Hard"
	sm.parse_sm()
