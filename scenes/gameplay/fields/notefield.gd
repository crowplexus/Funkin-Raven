extends Control
class_name NoteField

@onready var receptors: Control = $"receptors"

var player: Player = null


func make_playable(new_player: Player = null) -> void:
	if new_player == null:
		new_player = Player.new()
	player = new_player
	print_debug("adding player ", get_index() + 1)
	add_child(player)


#region Animations

func play_static(key: int) -> void:
	var receptor: = receptors.get_child(key)
	receptor.scale = Vector2(0.5, 0.5)
	receptor.modulate.v = 1.0


func play_ghost(key: int) -> void:
	var receptor: = receptors.get_child(key)
	receptor.scale = Vector2(0.4, 0.4)
	receptor.modulate.v = 0.5


func play_glow(key: int) -> void:
	var receptor: = receptors.get_child(key)
	receptor.scale = Vector2(0.45, 0.45)
	receptor.modulate.v = 3.0

#endregion
