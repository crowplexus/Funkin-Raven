extends Node2D
## Handles Player Input, Scoring, and your taxes.
class_name Player

#region Scoring

const MAX_SCORE: int = 500
const JUDGMENTS: Array[Dictionary] = [
	{
		"name": "epic", "splash": true,
		"accuracy": 100.0, "threshold": 22.5,
		"color": Color("ff89c9"),
	},
	{
		"name": "sick", "splash": true,
		"accuracy": 90.0, "threshold": 45.0,
		"color": Color("626592"),
	},
	{
		"name": "good", "splash": false,
		"accuracy": 85.0, "threshold": 90.0,
		"color": Color("77d0c1"),
	},
	{
		"name": "bad", "splash": false,
		"accuracy": 30.0, "threshold": 135.0,
		"color": Color("f7433f"),
	},
	{
		"name": "shit", "splash": false,
		"accuracy": 0.0, "threshold": 180.0,
		"color": Color("e5af32"),
	},
	{
		"name": "miss", "splash": false,
		"accuracy": 0.0, "threshold": NAN,
		"color": Color.DIM_GRAY,
	},
]

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

signal note_hit(hit_result: NoteData.HitResult)
signal note_miss(column: int)

@export var controls: PackedStringArray = ["note0", "note1", "note2", "note3"]

var note_queue: Array[NoteData] = []

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

	var input_notes: Array[NoteData] = note_queue.filter(func(queued: NoteData):
		var is_player: bool = $"../".get_index() == queued.player
		var hit_threshold: float = JUDGMENTS[JUDGMENTS.size() - 2].threshold * 0.001
		return (is_player and queued.column == key and
			(queued.time - Conductor.time) < hit_threshold and
			queued.hit_flag == 0)
	)

	if e.is_pressed() and input_notes.is_empty():
		$"../".receptors.get_child(key).scale *= 0.8
		$"../".call_deferred("play_ghost", key)
		return

	if input_notes.size() > 1:
		input_notes.sort_custom(NoteData.sort_by_time)
	#print_debug(input_notes)

	if e.is_released():
		# ghost tapping here
		# also reset receptor animation
		$"../".call_deferred("play_static", key)
		return

	var note: NoteData = input_notes[0]
	if is_instance_valid(note.object):
		note.object.call_deferred("hit_behaviour", note)
		note.object.free()

	$"../".call_deferred("play_glow", key)
	note.hit_flag = 1 # flag the note as hit
	send_hit_result(note)


func send_hit_result(note: NoteData) -> void:
	var diff: float = note.time - Conductor.time
	var judge: Dictionary = get_judgment(absf(diff *  1000.0))

	var hit_colour: Color = Color.DIM_GRAY
	if "color" in judge: hit_colour = judge.color

	var cur: = get_tree().current_scene
	cur.hit_result_label.text = (str(judge.name) +
		"\nTiming: %sms" % snappedf(diff * 1000.0, 0.01))
	cur.hit_result_label.modulate = hit_colour

	var hit_result: = NoteData.HitResult.new()
	hit_result.millisecond = diff * 1000.0
	hit_result.judgment = judge
	hit_result.player = self
	hit_result.data = note
	note_hit.emit(hit_result)

	score += 350
	health += floori(3 * note.hold_length)
	accuracy_threshold += judge.accuracy
	total_notes_hit += 1
	combo += 1

	await RenderingServer.frame_post_draw
	hit_result.unreference()


func get_judgment(time: float) -> Dictionary:
	var result: Dictionary = JUDGMENTS.back()

	for i: int in JUDGMENTS.size():
		var judgment: Dictionary = JUDGMENTS[i]
		if judgment.threshold == NAN:
			continue

		if time <= judgment.threshold:
			result = judgment
			break

	return result

#endregion
