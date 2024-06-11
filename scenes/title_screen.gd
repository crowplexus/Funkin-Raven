extends Node2D


func _ready() -> void:
	Chart.global = Chart.request("b4cksl4sh", "hard")
	await RenderingServer.frame_post_draw
	get_tree().change_scene_to_packed(load("res://scenes/gameplay/gameplay.tscn"))
