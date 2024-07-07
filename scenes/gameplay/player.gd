extends Node2D
## Handles Player Input, Scoring, and your taxes.
class_name Player

signal note_hit(note: Note, is_tap: bool)
signal botplay_hit(note: Note, is_tap: bool)
signal note_fly_over(note: Note)
signal combo_break(note: Note)
signal note_miss(column: int)

@export var stats: PlayerStats
## Your current health value, starts at max_health / 2.
@export var health: int = 0: # this is set on the _ready() function
	set(health_value):
		health = clampi(health_value, 0, max_health)
## Defines your max health value.
@export var max_health: int = 100

@export var notefield: NoteField
@export var controls: PackedStringArray = ["note0", "note1", "note2", "note3"]
@export var botplay: bool = false

## Note queue for the player to hit.
var note_queue: Array[Note] = []
## Hold note queue, used for hold inputs.
var hold_note_queue: Array[Note] = []
## Buttons being held by the player, for hold note input checks.
var held_buttons: Array[bool] = []

func _ready() -> void:
	health = max_health / 2
	stats = PlayerStats.new()
	if is_instance_valid(notefield):
		held_buttons.resize(notefield.key_count)
		held_buttons.fill(false)

#region Input Handler

func _process(delta: float) -> void:
	if not note_queue.is_empty():
		for qnote: Note in note_queue:
			if qnote.finished:
				continue

			if qnote.moving and (qnote.time - Conductor.time) < -0.3:
				if (qnote.time - Conductor.time) < -(0.3 + qnote.hold_progress - 0.5):
					if qnote.object and qnote.object.has_method("on_miss"):
						qnote.object.call_deferred("on_miss", qnote.column)
					qnote.hit_result = send_hit_result(qnote, true)
					# not needed anymore since the above call forces a miss
					#apply_miss(q_note.column)
					note_fly_over.emit(qnote)
					finish_note(qnote)

			# TODO: rework all of this for replays.
			if botplay and qnote.time <= Conductor.time:
				#var fake_ievent: = InputEventAction.new()
				#fake_ievent.action = controls[qnote.column]
				#fake_ievent.pressed = true
				#Input.parse_input_event(fake_ievent)
				note_hit_tap(qnote)
				if is_instance_valid(notefield):
					notefield.botplay_receptor(qnote)
					notefield.on_note_hit(qnote, true)
				if qnote.hold_progress > 0.0:
					qnote.update_hold = true
					qnote.moving = false
					if is_instance_valid(notefield) and Conductor.ibeat % 1 == 0:
						notefield.play_glow(qnote.column)
					update_hold_note(qnote)

	if not hold_note_queue.is_empty():
		manage_hit_queue(delta)


func _unhandled_input(e: InputEvent) -> void:
	if botplay:
		return
	var key: int = get_column_event(e)
	if key == -1:
		return
	held_buttons[key] = Input.is_action_pressed(controls[key])
	if Input.is_action_just_pressed(controls[key]):
		input_press(key)
	if Input.is_action_just_released(controls[key]):
		input_release(key)

## Ran whenever you press inputs.
func input_press(key: int) -> void:
	var input_notes: Array[Note] = note_queue.filter(func(queued: Note):
		var hit: bool = (queued.time - Conductor.time) < Scoring.HIT_THRESHOLD * 0.001
		return queued.column == key and not queued.hit_result and not queued.finished and hit
	)
	if input_notes.is_empty():
		if not Preferences.ghost_tapping:
			apply_miss(key)
		if is_instance_valid(notefield) and notefield.has_method("play_ghost"):
			notefield.call_deferred("play_ghost", key)
		return
	if input_notes.size() > 1:
		input_notes.sort_custom(Note.sort_by_time)

	var tap: Note = input_notes[0]
	if tap.time < Conductor.time: tap.hit_timing = 2
	else: tap.hit_timing = 1
	if tap.hold_progress > 0.0:
		tap.trip_timer = 1.0

	note_hit_tap(tap)
	if tap.hold_progress > 0.0:
		hold_note_queue.append(tap)
	if is_instance_valid(notefield):
		notefield.on_note_hit(tap, true)
		# play animation in receptor
		if notefield.has_method("play_glow"):
			notefield.call_deferred("play_glow", tap.column)

## Ran whenever you release inputs.
func input_release(key: int) -> void:
	if is_instance_valid(notefield) and notefield.has_method("play_static"):
		notefield.call_deferred("play_static", key)

## Returns a column from 0 to [code]controls.size()[/code]
## Used by [code]_unhandled_key_input[/code] for knowing which note you are trying to hit.
func get_column_event(_event: InputEvent) -> int:
	for i: int in controls.size():
		if _event.is_action(controls[i]):
			return i
	return -1

## Note hit function for tap notes[br]
## Increases score and accuracy and judges your hit.
func note_hit_tap(note: Note) -> void:
	if stats.combo < 0:
		stats.combo = 0

	var hit_result: Note.HitResult = send_hit_result(note, true)
	if not note.hit_result: note.hit_result = hit_result

	if note.hit_result:
		var combo_broke: bool = false
		if note.hit_result.judgment and "combo_break" in note.hit_result.judgment:
			combo_broke = note.hit_result.judgment.combo_break == true
		if note.object:
			if note.object.has_method("on_hit"):
				note.object.callv("on_hit", [note])
			if combo_broke:
				note.object.modulate.a = 0.4
				note.object.modulate.v = 3.0
				combo_break.emit(note)
	if note.hold_progress > 0.0:
		note.moving = false
	if note.hold_progress <= 0.0:
		finish_note(note)

## Handles hold note input.
func hold_note_input(hold: Note, delta: float = 0.0) -> void:
	if hold.dropped or hold.hold_progress == 0.0:
		return
	if hold.receptor and hold.object:
		hold.object.position.y = hold.receptor.global_position.y
	if hold.column <= held_buttons.size():
		hold.update_hold = true
		if held_buttons[hold.column] == true:
			if Conductor.ibeat % 1 == 0:
				note_hit_hold(hold)
				if is_instance_valid(notefield):
					notefield.play_glow(hold.column)
					notefield.on_note_hit(hold, false)
		else:
			hold.trip_timer -= 0.05 * hold.hold_length
		if hold.trip_timer <= 0.0:
			hold.update_hold = false
			if hold.object and hold.object.has_method("on_miss"):
				hold.object.call_deferred("on_miss", hold.column)
			apply_miss(hold.column)
			hold.dropped = true
			hold.moving = true
			if is_instance_valid(notefield):
				notefield.play_static(hold.column)
			hold_note_queue.erase(hold)

## Loops through notes that have been hit[br]
## this function is used mainly to handle hold note inputs
func manage_hit_queue(delta: float) -> void:
	if delta == 0.0: delta = get_process_delta_time()
	for hold: Note in hold_note_queue:
		if hold.finished:
			continue
		if not hold.dropped and not botplay:
			hold_note_input(hold)
		if is_instance_valid(notefield) and botplay and Conductor.ibeat % 1 == 0:
			notefield.play_glow(hold.column)
		if hold.hold_progress <= 0.0:
			hold_note_queue.erase(hold)
		update_hold_note(hold)

## Note hit function for hold notes[br]
## Increases score by 10 every frame when holding.
func note_hit_hold(note: Note) -> void:
	#stats.score = stats.score + 15
	if note:
		if Conductor.ibeat % 2 == 0 or note.hold_progress <= 0.0:
			note_hit.emit(note, false)
		if note.hit_result and note.hold_progress < 0.0:
			note.hit_result.unreference()
			#hold_note_queue.erase(note)

## Updates a hold note's size and objects.
func update_hold_note(note: Note, delta: float = 0.0) -> void:
	if delta == 0.0: delta = get_process_delta_time()
	var rel_time: float = note.time - Conductor.time
	if note.update_hold:
		if note.hit_timing == 2 and rel_time < 0.0:
			note.hold_progress += rel_time
			note.hit_timing = 0
		var nscale: float = note.object.scale.x if note.object else 0.7
		note.hold_progress -= delta / absf(nscale)
		if note.object and  note.object.has_method("update_hold_size"):
			note.object.call_deferred("update_hold_size")
	if note.hold_progress <= 0.0:
		finish_note(note)

## Queues a note as finished, used for input.
func finish_note(note: Note) -> void:
	note.finished = true
	#note.moving = false
	if is_instance_valid(note.object) and note.object.has_method("finish"):
		note.object.call_deferred("finish")
	if note.hold_progress < 0.0:
		note.update_hold = false
	if is_instance_valid(note.object):
		note.object.queue_free()

#endregion
#region Stats and Score

## Sends a hit result
func send_hit_result(note: Note, is_tap: bool = true) -> Note.HitResult:
	var diff: float = note.time - Conductor.time
	var update_stats: Callable = func(accuracy: float) -> void:
		var hit_score: = Scoring.TEMPLATE_HIT_SCORE.duplicate()
		hit_score.health = health + 3
		hit_score.accuracy = stats.accuracy_threshold + accuracy
		hit_score.score = stats.score + Scoring.get_doido_score(diff * 1000.0)
		hit_score.total_notes_hit = stats.total_notes_hit + 1
		hit_score.combo = stats.combo + 1
		apply_score(hit_score)

	if botplay:
		var perfect: Dictionary = Scoring.JUDGMENTS.perfect.duplicate()
		perfect.name = Scoring.JUDGMENTS.find_key(perfect)
		perfect.frame = Scoring.JUDGMENTS.keys().find(perfect.name)
		note.hit_result = Note.HitResult.make(self, diff * 1000.0, perfect)
		update_stats.call(perfect.accuracy)
		botplay_hit.emit(note, is_tap)
		# caused a funny bug which made the combo popups play on botplay holds
		#note_hit.emit(note, is_tap)
		return note.hit_result

	var judge: Dictionary = Scoring.judge_note(note, absf(diff * 1000.0)).duplicate()
	var judge_name: String = Scoring.JUDGMENTS.find_key(judge)
	match judge_name:
		"sick" when not Preferences.use_epics:
			judge.accuracy = 100.0
		"miss":
			apply_miss(note.column)
			judge.name = judge_name
			judge.frame = Scoring.JUDGMENTS.keys().find(judge_name)
			return Note.HitResult.make(self, diff * 1000.0, judge)

	if stats.combo > 1 and judge.combo_break == true:
		stats.combo = 0
		stats.breaks += 1
	if judge_name in stats.hit_registry:
		stats.hit_registry[judge_name] += 1

	judge.name = judge_name
	judge.frame = Scoring.JUDGMENTS.keys().find(judge_name)
	note.hit_result = Note.HitResult.make(self, diff * 1000.0, judge)
	update_stats.call(judge.accuracy)
	note_hit.emit(note, is_tap)
	return note.hit_result

## Increases score values and accuracy if provided.[br]
## NOTE: please copy [code]Scoring.TEMPLATE_HIT_SCORE[/code]
## and modify its values when using this
func apply_score(score_struct: Dictionary) -> void:
	if "score" in score_struct:
		stats.score = score_struct.score
	if "health" in score_struct:
		health = score_struct.health
	if "accuracy" in score_struct:
		stats.accuracy_threshold = score_struct.accuracy
	if "total_notes_hit" in score_struct:
		stats.total_notes_hit = score_struct.total_notes_hit
	if "combo" in score_struct:
		stats.combo = score_struct.combo

## Increases misses and breaks combo if needed
func apply_miss(column: int = 0) -> void:
	if column < 0: column = 0
	if stats.combo > 1:
		stats.combo = 0
		stats.breaks += 1
	else:
		stats.combo -= 1
	health -= 3
	stats.misses += 1
	note_miss.emit(column)

#endregion
