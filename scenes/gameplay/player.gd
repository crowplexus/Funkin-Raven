extends Node2D
## Handles Player Input, Scoring, and your taxes.
class_name Player

#region Scoring

	# scoring values #

@export var score:  int = 0
#	get:
#		# convert accuracy to score
#		# increase by note hits
#		# decrease by misses.
#		return 0
@export var breaks: int = 0
@export var misses: int = 0
@export var combo : int = 0

@export var health: int = 50:
	set(health_value):
		health = clampi(health_value, 0, max_health)
@export var max_health: int = 100

	# accuracy values #

@export var accuracy: float = 0.0:
	get:
		if total_notes_hit == 0: return 0.00
		return accuracy_threshold / (total_notes_hit + misses)

@export var accuracy_threshold: float = 0.0
@export var total_notes_hit: int = 0

#endregion

func mk_stats_string() -> String:
	return "[Score]: %s / [Combo Breaks]: %s / [Accuracy]: %s" % [
		score, breaks, str(snappedf(accuracy, 0.01)) + "%"
	]


#region Player Input

signal note_hit(hit_result: Note.HitResult)
signal note_miss(column: int)

@export var controls: PackedStringArray = ["note0", "note1", "note2", "note3"]

var note_queue: Array[Note] = []

func get_column_event(_event: InputEvent) -> int:
	for i: int in controls.size():
		if (Input.is_action_just_pressed(controls[i]) or
			Input.is_action_just_released(controls[i])):
			return i
	return -1


func _unhandled_key_input(e: InputEvent) -> void:
	var key: int = get_column_event(e)
	if key == -1:
		return

	var input_notes: Array[Note] = note_queue.filter(func(queued: Note):
		var is_player: bool = $"../".get_index() == queued.player
		var hit_threshold: float = Scoring.JUDGMENTS[Scoring.JUDGMENTS.size() - 2].threshold * 0.001
		return (is_player and queued.column == key and
			(queued.time - Conductor.time) < hit_threshold and
			queued.hit_flag == 0)
	)

	if e.is_pressed() and input_notes.is_empty():
		$"../".receptors.get_child(key).scale *= 0.8
		$"../".call_deferred("play_ghost", key)
		return

	if input_notes.size() > 1:
		input_notes.sort_custom(Note.sort_by_time)
	#print_debug(input_notes)

	if e.is_released():
		# ghost tapping here
		# also reset receptor animation
		$"../".call_deferred("play_static", key)
		return

	var note: Note = input_notes[0]
	if is_instance_valid(note.object):
		note.object.call_deferred("hit_behaviour", note)
		note.object.free()

	$"../".call_deferred("play_glow", key)
	note.hit_flag = 1 # flag the note as hit
	send_hit_result(note)

## Constructs a hit result.
func send_hit_result(note: Note) -> void:
	var diff: float = note.time - Conductor.time
	var judge: Dictionary = Scoring.judge_note(absf(diff *  1000.0), note)

	var hit_colour: Color = Color.DIM_GRAY
	if "color" in judge: hit_colour = judge.color
	elif "colour" in judge: hit_colour = judge.colour # british.

	var cur: = get_tree().current_scene
	cur.hit_result_label.text = (str(judge.name) +
		"\nTiming: %sms" % snappedf(diff * 1000.0, 0.01))
	cur.hit_result_label.modulate = hit_colour

	var hit_result: = Note.HitResult.new()
	hit_result.hit_time = diff * 1000.0
	hit_result.judgment = judge
	hit_result.player = self
	hit_result.data = note
	note_hit.emit(hit_result)

	var hit_score: = Scoring.TEMPLATE_HIT_SCORE.duplicate()
	hit_score.health = health + floori(3 * note.hold_length)
	hit_score.accuracy = accuracy_threshold + judge.accuracy
	hit_score.total_notes_hit = total_notes_hit + 1
	hit_score.score = score + 350
	hit_score.combo = combo + 1

	apply_score(hit_score)

	await RenderingServer.frame_post_draw
	hit_result.unreference()

## wow
func apply_score(score_struct: Dictionary) -> void:
	if "score" in score_struct:
		score = score_struct.score
	if "health" in score_struct:
		health = score_struct.health
	if "accuracy" in score_struct:
		accuracy_threshold = score_struct.accuracy
	if "total_notes_hit" in score_struct:
		total_notes_hit = score_struct.total_notes_hit
	if "combo" in score_struct:
		combo = score_struct.combo
#endregion
