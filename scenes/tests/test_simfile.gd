extends Node2D

func _ready() -> void:
	var p: String = "res://assets/songs/I Got No Time/I Got No Time.sm"
	var file: = FileAccess.open(p, FileAccess.READ).get_as_text()

	var sm: = Chart.PARSERS.stepmania.new()
	sm.data = file
	sm.parse_sm()
