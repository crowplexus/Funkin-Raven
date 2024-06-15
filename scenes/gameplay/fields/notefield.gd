extends Control
class_name NoteField

@onready var receptors: Control = $"receptors"

@export var connected_characters: Array[Character] = []
@export var scroll_mods: PackedVector2Array = []
@export var player: Player = null


func reset_scroll_mods() -> void:
	var mod_pos: Vector2 = Vector2(1.0, 1.0)
	match Preferences.scroll_direction:
		1: mod_pos = Vector2(1.0, -1.0)

	for i: int in receptors.get_child_count():
		var receptor: CanvasItem = receptors.get_child(i)
		scroll_mods.append(mod_pos)
		match mod_pos:
			Vector2(1.0, -1.0):
				receptor.position.y = 330


func make_playable(new_player: Player = null) -> void:
	if new_player == null:
		new_player = Player.new()
	print_debug("adding player ", get_index() + 1)
	player = new_player
	add_child(player)


func get_receptor(column: int) -> CanvasItem:
	if column < 0 or column > receptors.get_child_count():
		column = 0
	return receptors.get_child(column)

#region Animations

func play_static(key: int) -> void:
	var receptor: = receptors.get_child(key)
	receptor.play("%s static" % key)


func play_ghost(key: int) -> void:
	var receptor: = receptors.get_child(key)
	receptor.play("%s press" % key)


func play_glow(key: int) -> void:
	var receptor: = receptors.get_child(key)
	receptor.play("%s confirm" % key)

#endregion
