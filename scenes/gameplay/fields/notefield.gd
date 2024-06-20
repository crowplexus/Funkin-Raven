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

func on_note_hit(hit_result: Note.HitResult, is_tap: bool) -> void:
	if not is_instance_valid(hit_result.data):
		return
	chars_sing(hit_result.data.column, is_tap or Conductor.ibeat % 1 == 0)


func reset_scroll_mods() -> void:
	var mod_pos: Vector2 = Vector2(1.0, 1.0)
	match Preferences.scroll_direction:
		1: mod_pos = Vector2(1.0, -1.0)

	animation_timers.resize(key_count)
	animation_timers.fill(Timer.new())

	for i: int in key_count:
		#if receptors.get_child_count() < i:
		#	var mmmm: = receptors.get_child(i % receptors.get_child_count())
		#	var copy: = mmmm.duplicate()
		#	copy.position.x += 160 * i
		#	copy.name = str(i)
		#	receptors.add_child(copy)

		var receptor: CanvasItem = receptors.get_child(i % receptors.get_child_count())
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
	print_debug("adding player ", get_index() + 1, " is bot? ", new_player.botplay)
	player = new_player
	add_child(player)


func get_receptor(column: int) -> CanvasItem:
	if column < 0 or column > receptors.get_child_count():
		column = 0
	return receptors.get_child(column)

#endregion
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


func botplay_receptor(note: Note) -> void:
	if not is_instance_valid(note):
		return

	var anim_timer: Timer = animation_timers[note.column]
	if is_instance_valid(anim_timer):
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


func chars_sing(column: int = 0, force: bool = false, cooldown_delay: float = 0.0) -> void:
	# putting faith in godot's looping :pray:
	for personaje: Character in connected_characters:
		if personaje.animation_context != 2:
			var sing_column: int = column % personaje.sing_list.size()
			personaje.sing(sing_column, force)
			personaje.idle_cooldown = (12 * Conductor.semiquaver) + cooldown_delay

#endregion
