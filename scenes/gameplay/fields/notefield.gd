extends Control
class_name NoteField

@onready var receptors: Control = $"receptors"

@export var connected_characters: Array[Character] = []
@export var scroll_mods: PackedVector2Array = []
@export var player: Player = null
@export var key_count: int = 4

var animation_timers: Array[Timer] = []
## Warps the notefield to either the Left (0) side of the screen
## Center (0.5, or Right (1).
var playfield_warp: float:
	set(new_warp):
		match new_warp:
			0: position.x = 100
			0.5: position.x = 305
			1: position.x = 500
		playfield_warp = new_warp


func reset_scroll_mods() -> void:
	var mod_pos: Vector2 = Vector2(1.0, 1.0)
	match Preferences.scroll_direction:
		1: mod_pos = Vector2(1.0, -1.0)

	for i: int in receptors.get_child_count():
		var receptor: CanvasItem = receptors.get_child(i)
		animation_timers.append(Timer.new())
		receptor.add_child(animation_timers[i])
		scroll_mods.append(mod_pos)

		match mod_pos:
			Vector2(1.0, -1.0):
				receptor.position.y = 330


func make_playable(new_player: Player = null) -> void:
	if new_player == null:
		new_player = Player.new()
	print_debug("adding player ", get_index() + 1, " is bot? ", new_player.botplay)
	player = new_player
	add_child(player)


func get_receptor(column: int) -> CanvasItem:
	if column < 0 or column > receptors.get_child_count():
		column = 0
	return receptors.get_child(column)


func botplay_receptor(note: Note) -> void:
	if not is_instance_valid(note):
		return

	var anim_timer: Timer = animation_timers[note.column]
	if is_instance_valid(anim_timer):
		anim_timer.stop()

	anim_timer.start((0.5 * Conductor.crotchet) + note.hold_length)
	play_glow.call_deferred(note.column)
	await anim_timer.timeout
	play_static.call_deferred(note.column)

#region Animations

func play_static(key: int) -> void:
	var receptor: = receptors.get_child(key)
	receptor.frame = 0
	receptor.play("%s static" % key)


func play_ghost(key: int) -> void:
	var receptor: = receptors.get_child(key)
	receptor.frame = 0
	receptor.play("%s press" % key)


func play_glow(key: int) -> void:
	var receptor: = receptors.get_child(key)
	receptor.frame = 0
	receptor.play("%s confirm" % key)

#endregion
