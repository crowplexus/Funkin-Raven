extends Node2D
## Handles Player Input, Scoring, and your taxes.
class_name Player

#region Scoring

	# scoring values #
## Score, 0 by default.
@export var score:  int = 0
#	get:
#		# convert accuracy to score
#		# increase by note hits
#		# decrease by misses.
#		return 0
## Combo Breaks, 0 by default
@export var breaks: int = 0
## Note Misses, 0 by default.
@export var misses: int = 0
## Note Combo, 0 by default.
@export var combo : int = 0
## Your current health value, starts at max_health / 2.
@export var health: int = 0: # this is set on the _ready() function
	set(health_value):
		health = clampi(health_value, 0, max_health)
## Defines your max health value.
@export var max_health: int = 100
## Contains judgments that you've hit.
@export var jhit_regis: Dictionary = {}

	# accuracy values #
## Accuracy, used to measure how accurate are your note hits in a percentage form[br]
## 0.00% by default
@export var accuracy: float = 0.0:
	get:
		if total_notes_hit == 0: return 0.00
		return accuracy_threshold / (total_notes_hit + misses)

@export var accuracy_threshold: float = 0.0
@export var total_notes_hit: int = 0

#endregion

func mk_stats_string() -> String:
	var status: String = "[Score]: %s / [Combo Breaks]: %s / [Accuracy]: %s" % [
		score, breaks, str(snappedf(accuracy, 0.01)) + "%"
	]
	# crazy frog.
	var cf: String = ""
	if breaks == 0:
		cf = Scoring.get_clear_flag(jhit_regis)
	else:
		if breaks < 10:
			if breaks == 1: cf = "MF"
			else: cf = "SDCB"

	if not cf.is_empty(): status += " (%s)" % cf
	return status


func _ready() -> void:
	health = max_health / 2
	for judge: Dictionary in Scoring.JUDGMENTS:
		jhit_regis[judge.name] = 0

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
		var hit_threshold: float = Scoring.JUDGMENTS.back().threshold * 0.001
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

## Sends a hit result
func send_hit_result(note: Note) -> void:
	var diff: float = note.time - Conductor.time
	var judge: Dictionary = Scoring.judge_note(absf(diff *  1000.0), note)

	if judge.name in jhit_regis:
		jhit_regis[judge.name] += 1

	if combo > 1 and "combo_break" in judge and judge.combo_break == true:
		combo = 0
		breaks += 1

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

## increases score values and accuracy if provided.[br]
## NOTE: please copy [code]Scoring.TEMPLATE_HIT_SCORE[/code]
## and modify its values when using this
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

## increases misses and breaks combo if needed
func apply_miss(column: int = 0) -> void:
	if column < 0: column = 0
	if combo > 1:
		combo = 0
		breaks += 1
	misses += 1
	note_miss.emit(column)
#endregion
