extends Node2D
## Handles Player Input, Scoring, and your taxes.
class_name Player

## Player's current stats, such as score, note misses, etc
@export var tallies: Tally
## List of player controls.
@export var controls: Array[String] = []
## Notefield attached to the player.
@export var notefield: NoteField
## Array of notes that can be hit by the player.
@export var note_list: Array[Note] = []
## Makes it so the player controls itself with no input.
@export var autoplay: bool = false
## Kinda explains itself.
var holds_to_update: Array[Note] = []
var buttons_held: Array[bool] = []

var note_hit: Callable = func(_note: Note) -> void:
	pass
var note_miss: Callable = func(_column: int = 0, _note: Note = null) -> void:
	pass

#region Built-in functions

func _ready() -> void:
	if not tallies:
		tallies = Tally.new()
	buttons_held.resize(notefield.key_count)
	buttons_held.fill(false)

func _process(delta: float) -> void:
	if not note_list.is_empty():
		if autoplay:
			parse_autoplay_input(delta)
		if not holds_to_update.is_empty():
			process_player_holds(delta)

# LET'S GO GAMBLING!!!
func _unhandled_input(event: InputEvent) -> void:
	var key: int = get_action_idx(event)
	if key == -1:
		return

	buttons_held[key] = Input.is_action_pressed(controls[key])

	if Input.is_action_just_pressed(controls[key]):
		# i'll keep this as simple as possible cus i'm also gonna use for replays
		var nearby_taps: Array[Note] = get_nearby_notes(key)
		if nearby_taps.is_empty():
			if not Preferences.ghost_tapping:
				tallies.apply_ghost_tap(key)
				if note_miss: note_miss.call(key, null)
			notefield.play_ghost(key)
			return
		if nearby_taps.size() > 1:
			# i don't trust myself
			nearby_taps.sort_custom(Note.sort_by_time)
		# hit the notes like this for now.
		var note: Note = nearby_taps[0] as Note
		note.hit_timing = 2 if note.time < Conductor.time else 1
		note.moving = false
		# set note judgement.
		note.hit_result = get_hit_result(note)
		# send hold note data (if possible)
		if note.hold_length > 0.0:
			note.trip_timer = 1.0
			note._late_hold = (note.time - Conductor.time) < 0.0
			holds_to_update.append(note)
		note_hit_common(note)
		notefield.play_glow(key)

	if Input.is_action_just_released(controls[key]):
		notefield.play_static(key)

#endregion

#region Hold Input

func parse_autoplay_input(delta: float = 0) -> void:
	for note: Note in note_list:
		if not note.finished and note.time <= Conductor.time:
			note.hit_result = get_hit_result(note)
			if note.moving:
				note_hit_common(note)
			note.moving = false
			if note.hold_progress > 0.0:
				update_hold_size(note, delta)
			notefield.autoplay_receptor(note)

func process_player_holds(delta: float = 0) -> void:
	for hold: Note in holds_to_update:
		if hold.hold_progress == 0.0:
			continue
		update_hold_size(hold, delta)
		# INPUT
		var do_not_talk_about_my_girlfriend: bool = not hold.dropped
		if do_not_talk_about_my_girlfriend:
			if buttons_held[hold.column] == true:
				if Conductor.ibeat % 1 == 0:
					notefield.play_glow(hold.column)
			else:
				hold.trip_timer -= 0.05 * hold.hold_length
			if hold.trip_timer <= 0.0:
				if is_instance_valid(hold.object) and hold.object.has_method("on_miss"):
					hold.object.call_deferred("on_miss", hold.column)
				hold.dropped = true
				hold.moving = true
				kill_note(hold)

func update_hold_size(hold: Note, delta: float = 0) -> void:
	if hold.dropped or hold.hold_progress <= 0.0:
		return

	if delta == 0: get_process_delta_time()
	if is_instance_valid(hold.receptor) and is_instance_valid(hold.object):
		hold.object.global_position.y = hold.receptor.global_position.y

	var hold_scale: float = hold.object.scale.x if is_instance_valid(hold.object) else 0.7
	if hold._late_hold:
		hold.hold_progress += (hold.time - Conductor.time) #/ absf(hold_scale)
		hold._late_hold = false
	hold.hold_progress -= delta / absf(hold_scale)
	if hold.object and hold.object.has_method("update_hold_size"):
		hold.object.call_deferred("update_hold_size")
	if hold.hold_progress <= 0.0:
		kill_note(hold)

func kill_note(note: Note) -> void:
	note.finished = true
	if is_instance_valid(note.object):
		if note.object.has_method("finish"):
			note.object.call_deferred("finish")
		note.object.queue_free()
	if holds_to_update.has(note):
		holds_to_update.erase(note)
	note_list.erase(note)

#endregion

#region Judging

func note_hit_common(note: Note) -> void:
	# increase score.
	if "combo_break" in note.hit_result.judgment and note.hit_result.judgment.combo_break == true:
		tallies.break_combo()
	match note.hit_result.judgment.name:
		"miss":
			tallies.apply_miss(note.column, note)
			await RenderingServer.frame_post_draw
			if note_miss: note_miss.call(note.column, note)
		_:
			tallies.apply_hit(note)
			if note_hit: note_hit.call(note)
	# free the note object.
	if is_instance_valid(note.object) and note.object.has_method("on_hit"):
		note.object.call_deferred("on_hit", note)
	if note.hold_progress <= 0.0:
		kill_note(note)

func get_hit_result(note: Note) -> Note.HitResult:
	var diff: float = (note.time - Conductor.time)

	if autoplay: # always return perfect in autoplay.
		var perfect: Dictionary = Scoring.JUDGMENTS.perfect.duplicate()
		perfect.name = Scoring.JUDGMENTS.find_key(perfect)
		perfect.frame = Scoring.JUDGMENTS.keys().find(perfect.name)
		return Note.HitResult.make(self, (diff * 1000.0), perfect)

	var judgment: Dictionary = Scoring.judge_note(note, absf(diff * 1000.0)).duplicate()
	var judge_name: StringName = Scoring.JUDGMENTS.find_key(judgment)
	judgment.name = Scoring.JUDGMENTS.find_key(judgment)
	judgment.frame = Scoring.JUDGMENTS.keys().find(judgment.name)

	var result: Note.HitResult = Note.HitResult.make(self, (diff * 1000.0), judgment)
	var can_epic: bool = Preferences.use_epics and Preferences.timing_diff != "WEEK7"
	match judge_name:
		"sick" when not can_epic:
			judgment.accuracy = 100.0
	return result


#endregion

#region Utilities

## Gets the column of a note by using the key you just pressed.
func get_action_idx(ie: InputEvent) -> int:
	var k: int = -1
	for garlic_bread: int in controls.size():
		if ie.is_action(controls[garlic_bread]):
			k = garlic_bread
			break
	return k

## Grabs every single nearby note in the note list, for inputs so you can hit them.
func get_nearby_notes(key: int) -> Array[Note]:
	return note_list.filter(func(it: Note) -> bool:
		var is_near: bool = (it.time - Conductor.time) < Scoring.HIT_THRESHOLD * 0.001
		return it.column == key and not it.dropped and not it.finished and is_near)

#endregion
