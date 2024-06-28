extends Control
class_name NoteField

@export var connected_characters: Array[Character] = []
@export var scroll_mods: PackedVector2Array = []

@export var receptors: Array[CanvasItem] = []
@export var key_count: int = 4
@export var player: Player

var animation_timers: Array[Timer] = []
## Warps the notefield to either the Left (0) side of the screen
## Center (0.5, or Right (1).
var playfield_spot: float:
	set(new_warp):
		match new_warp:
			0.0: global_position.x = get_viewport_rect().size.x * 0.1
			0.5: global_position.x = get_viewport_rect().size.x * 0.36
			1.0: global_position.x = get_viewport_rect().size.x * 0.6
		if scale.x >= 1.0:
			global_position.x /= scale.x
		else:
			global_position.x *= scale.x
		#global_position.x *= absf(scale.x)
		playfield_spot = new_warp


#region Player

func on_note_hit(note: Note, is_tap: bool) -> void:
	if not note:
		return
	var suffix: String = ""
	match note.kind:
		"altanim", "altAnim", "Alt Animation": suffix = "-alt"
		_: suffix = ""
	if note.hold_length > 0.0:
		suffix += "-hold"
	chars_sing(-1, note.column, is_tap, suffix)


func reset_scroll_mods() -> void:
	var mod_pos: Vector2 = Vector2(1.0, 1.0)
	match Preferences.scroll_direction:
		1: mod_pos = Vector2(1.0, -1.0)

	animation_timers.resize(key_count)
	animation_timers.fill(Timer.new())

	for i: int in key_count:
		if receptors.size() < key_count:
			var mmmm: = receptors[i % receptors.size()]
			var copy: = mmmm.duplicate()
			copy.position.x = receptors.back().position.x + (i * 160)
			copy.name = str(i)
			add_child(copy)
			receptors.append(copy)

		var receptor: CanvasItem = receptors[i % receptors.size()]
		if not is_instance_valid(receptor):
			continue

		animation_timers.fill(Timer.new())
		receptor.add_child(animation_timers[i])
		scroll_mods.append(mod_pos)

		match mod_pos:
			Vector2(1.0, -1.0):
				receptor.position.y = 330


func make_playable(new_player: Player = null) -> void:
	if new_player == null:
		new_player = Player.new()
	#print_debug("adding player ", get_index() + 1, " is bot? ", new_player.botplay)
	player = new_player
	add_child(player)


## Safer way to get a receptor over doing receptors[column]
func get_receptor(column: int) -> CanvasItem:
	if column < 0 or column > receptors.size():
		column = 0
	return receptors[column]

#endregion
#region Animations

func play_static(key: int) -> void:
	var receptor: = receptors[key]
	receptor.frame = 0
	receptor.play("%s static" % key)


func play_ghost(key: int) -> void:
	var receptor: = receptors[key]
	receptor.frame = 0
	receptor.play("%s press" % key)


func play_glow(key: int) -> void:
	var receptor: = receptors[key]
	receptor.frame = 0
	receptor.play("%s confirm" % key)


func botplay_receptor(note: Note) -> void:
	if not is_instance_valid(note):
		return

	var anim_timer: Timer = animation_timers[note.column]
	if anim_timer:
		anim_timer.stop()
		anim_timer.start((0.2 * Conductor.crotchet) + note.hold_length)
		play_glow.call_deferred(note.column)
		await anim_timer.timeout
		play_static.call_deferred(note.column)

#endregion
#region Connected Characters

func chars_dance(force: bool = false, force_idle: int = -1) -> void:
	for character: Character in connected_characters:
		character.dance(force, force_idle)


func chars_sing(id: int = -1, column: int = 0, force: bool = false, suffix: String = "", cooldown_delay: float = 0.0) -> void:
	if id > -1 and id <= connected_characters.size():
		var sing_column: int = column % connected_characters[id].sing_list.size()
		connected_characters[id].sing(sing_column, force, suffix)
		connected_characters[id].idle_cooldown = (12 * Conductor.semiquaver) + cooldown_delay
		return
	# putting faith in godot's looping :pray:
	if id == -1: for personaje: Character in connected_characters:
		if personaje.animation_context != 2:
			var sing_column: int = column % personaje.sing_list.size()
			personaje.sing(sing_column, force, suffix)
			personaje.idle_cooldown = (12 * Conductor.semiquaver) + cooldown_delay

#endregion
