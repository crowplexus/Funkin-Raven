extends Node2D

@onready var receptors: Node2D = $"receptors"
var player: Player = null


func make_playable(new_player: Player = null) -> void:
	if new_player == null:
		new_player = Player.new()
	player = new_player
	print_debug("adding player ", get_index() + 1)
	add_child(player)
