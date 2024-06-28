extends Node2D
## Handles Player Input, Scoring, and your taxes.
class_name Player

#region Editor Variables

@export var stats: PlayerStats
## Your current health value, starts at max_health / 2.
@export var health: int = 0: # this is set on the _ready() function
	set(health_value):
		health = clampi(health_value, 0, max_health)
## Defines your max health value.
@export var max_health: int = 100

#endregion

func _ready() -> void:
	health = max_health / 2
	stats = PlayerStats.new()

#region Player Input

signal note_hit(note: Note, is_tap: bool)
signal botplay_hit(note: Note, is_tap: bool)
signal note_fly_over(note: Note)
signal combo_break(note: Note)
signal note_miss(column: int)

@export var controls: PackedStringArray = ["note0", "note1", "note2", "note3"]
@export var botplay: bool = false

## Notes that the player is able to hit.
var note_queue: Array[Note] = []
## Hold note queue, used for hold inputs.
var hold_note_queue: Array[Note] = []
## Buttons being held by the player, for hold note input checks.
var held_buttons: Array[bool] = []


func _process(delta: float) -> void:
	if not note_queue.is_empty():
		for my_note: Note in note_queue:
			if my_note.finished:
				continue

			if my_note.moving and (my_note.time - Conductor.time) < -0.3:
				my_note.hit_flag = -1
				if (my_note.time - Conductor.time) < -(0.3 + my_note.hold_progress - 0.5):
					if my_note.object and my_note.object.has_method("on_miss"):
						my_note.object.call_deferred("on_miss", my_note.column)
					my_note.hit_result = send_hit_result(my_note, true)
					# not needed anymore since the above call forces a miss
					#apply_miss(my_note.column)
					note_fly_over.emit(my_note)
					finish_note(my_note)

			if botplay and my_note.time <= Conductor.time:
				note_hit_tap(my_note)
				if my_note.notefield:
					my_note.notefield.botplay_receptor(my_note)
					my_note.notefield.on_note_hit(my_note, true)
				if my_note.hold_progress > 0.0:
					my_note.update_hold = true
					my_note.moving = false
					if Conductor.ibeat % 1 == 0 and is_instance_valid(my_note.notefield):
						my_note.notefield.play_glow(my_note.column)
					update_hold_note(my_note)

	if not hold_note_queue.is_empty():
		manage_hit_queue(delta)


func _unhandled_key_input(e: InputEvent) -> void:
	var key: int = get_column_event(e)
	if key == -1 or botplay:
		return

	if key <= held_buttons.size():
		held_buttons[key] = Input.is_action_pressed(controls[key])

	if Input.is_action_just_pressed(controls[key]):
		var input_notes: Array[Note] = note_queue.filter(func(queued: Note):
			var hit_threshold: float = Scoring.HIT_THRESHOLD * 0.001
			var can_be_hit: bool = (queued.time - Conductor.time) < hit_threshold
			return (queued.column == key and queued.hit_flag == 0
				and not queued.finished and can_be_hit)
		)
		if input_notes.size() > 1:
			input_notes.sort_custom(Note.sort_by_time)
		if input_notes.is_empty() and $"../".has_method("play_ghost"):
			$"../".call_deferred("play_ghost", key)
		else:
			var tap: Note = input_notes[0]
			if tap.time < Conductor.time: tap.hit_timing = 2
			else: tap.hit_timing = 1

			if tap.hold_progress > 0.0:
				tap.trip_timer = 1.5 * tap.hold_progress

			note_hit_tap(tap)
			if tap.hold_progress > 0.0:
				hold_note_queue.append(tap)
			tap.notefield.on_note_hit(tap, true)
			# play animation in receptor
			if $"../".has_method("play_glow"):
				$"../".call_deferred("play_glow", tap.column)

	elif Input.is_action_just_released(controls[key]):
		if not Preferences.ghost_tapping:
			apply_miss(key)
		if $"../".has_method("play_static"):
			$"../".call_deferred("play_static", key)

## Returns a column from 0 to [code]controls.size()[/code]
## Used by [code]_unhandled_key_input[/code] for knowing which note you are trying to hit.
func get_column_event(_event: InputEvent) -> int:
	for i: int in controls.size():
		if _event.is_action(controls[i]):
			return i
	return -1

## Loops through notes that have been hit[br]
## this function is used mainly to handle hold note inputs
func manage_hit_queue(delta: float) -> void:
	if delta == 0.0: delta = get_process_delta_time()

	for hold: Note in hold_note_queue:
		if hold.finished:
			continue

		if not hold.dropped:
			match hold.hit_flag:
				1: # player
					hold_note_input(hold)
				2: # botplay
					if Conductor.ibeat % 1 == 0 and is_instance_valid(hold.notefield):
						hold.notefield.play_glow(hold.column)
		if hold.hold_progress <= 0.0:
			hold_note_queue.erase(hold)
		update_hold_note(hold)


## Handles hold note input.
func hold_note_input(hold: Note, delta: float = 0.0) -> void:
	if hold.dropped or hold.hold_progress == 0.0:
		return
	if hold.receptor and hold.object:
		hold.object.position.y = hold.receptor.global_position.y
	if hold.column <= held_buttons.size():
		hold.update_hold = true
		if hold.hold_progress > 0.01:
			if held_buttons[hold.column] == false:
				hold.trip_timer -= 0.1
				if hold.object:
					hold.object.modulate.a = lerpf(hold.object.modulate.a, 0.8, exp(-delta * 0.5))
			else:
				if Conductor.ibeat % 1 == 0:
					note_hit_hold(hold)
					if hold.notefield:
						hold.notefield.play_glow(hold.column)
					hold.notefield.on_note_hit(hold, false)
			if hold.trip_timer <= 0.0:
				hold.update_hold = false
				if hold.object:
					hold.object.call_deferred("miss_behaviour", hold.column)
					hold.object.modulate.a = 0.3
				apply_miss(hold.column)
				hold.dropped = true
				hold.moving = true
				if hold.notefield:
					hold.notefield.play_static(hold.column)
				hold_note_queue.erase(hold)

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
	if note.hold_progress < 0.0:
		finish_note(note)

## Queues a note as finished, used for input.
func finish_note(note: Note) -> void:
	note.finished = true
	#note.moving = false
	if note.object:
		if note.object.has_method("finish"):
			note.object.call_deferred("finish")
	if note.hold_progress < 0.0:
		note.update_hold = false
	if note.object:
		note.object.queue_free()
	#if hit_note_queue.has(note):
	#	hit_note_queue.erase(note)

## Note hit function for tap notes[br]
## Increases score and accuracy and judges your hit.
func note_hit_tap(note: Note) -> void:
	if note.hit_flag == 0:
		note.hit_flag = 1 if not botplay else 2 # flag the note as hit

	if stats.combo < 0:
		stats.combo = 0

	var hit_result: Note.HitResult = send_hit_result(note, true)
	if not note.hit_result: note.hit_result = hit_result

	if note.hit_flag != 0:
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

## Note hit function for hold notes[br]
## Increases score by 10 every frame when holding.
func note_hit_hold(note: Note) -> void:
	stats.score = stats.score + 15
	if note:
		if Conductor.ibeat % 2 == 0 or note.hold_progress <= 0.0:
			note_hit.emit(note, false)
		if note.hit_result and note.hold_progress < 0.0:
			note.hit_result.unreference()
			#hold_note_queue.erase(note)


## Sends a hit result
func send_hit_result(note: Note, is_tap: bool = true) -> Note.HitResult:
	var diff: float = note.time - Conductor.time
	if botplay:
		var perfect: Dictionary = Scoring.JUDGMENTS.perfect.duplicate()
		perfect.name = Scoring.JUDGMENTS.find_key(perfect)
		perfect.frame = Scoring.JUDGMENTS.keys().find(perfect.name)
		note.hit_result = Note.HitResult.make(self, diff * 1000.0, perfect)
		botplay_hit.emit(note, is_tap)
		# caused a funny bug which made the combo popups play on botplay holds
		#note_hit.emit(note, is_tap)
		return note.hit_result

	var judge: Dictionary = Scoring.judge_note(note, absf(diff * 1000.0)).duplicate()
	var judge_name: String = Scoring.JUDGMENTS.find_key(judge)
	if judge_name == "miss":
		apply_miss(note.column)
		judge.name = judge_name
		judge.frame = Scoring.JUDGMENTS.keys().find(judge_name)
		return Note.HitResult.make(self, diff * 1000.0, judge)

	if stats.combo > 1 and judge.combo_break == true:
		stats.combo = 0
		stats.breaks += 1

	if judge_name in stats.hit_registry:
		stats.hit_registry[judge_name] += 1

	var hit_score: = Scoring.TEMPLATE_HIT_SCORE.duplicate()
	hit_score.health = health + 3
	hit_score.accuracy = stats.accuracy_threshold + judge.accuracy
	hit_score.score = stats.score + Scoring.get_raven_score(1)
	hit_score.total_notes_hit = stats.total_notes_hit + 1
	hit_score.combo = stats.combo + 1
	apply_score(hit_score)

	judge.name = judge_name
	judge.frame = Scoring.JUDGMENTS.keys().find(judge_name)
	note.hit_result = Note.HitResult.make(self, diff * 1000.0, judge)
	note_hit.emit(note, is_tap)
	#await RenderingServer.frame_post_draw
	#hit_result.unreference()
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
