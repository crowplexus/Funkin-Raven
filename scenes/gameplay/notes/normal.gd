extends Node2D


func _ready() -> void:
	pass


func hit_behaviour(_note: Note) -> void:
	pass


func miss_behaviour(_note: Note) -> void:
	modulate.a = 0.4
	pass
