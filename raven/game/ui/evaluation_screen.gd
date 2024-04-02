extends Control

@onready var panel: Panel = $"panel"
@onready var header: Label = $"panel/header"
@onready var footer: Label = $"panel/footer"
@onready var judgement_info: Label = $"panel/judgement_stuff"
@onready var note_info: Label = $"panel/judgement_stuff/note_stuff"

var close_callback: Callable = func():
	Tools.switch_scene(load("res://raven/game/menus/main_menu.tscn"))

var points: ScoreManager

func _ready():
	if PlayField.play_manager != null:
		points = PlayField.play_manager.points
	
	if PlayField.chart == null or points == null:
		close_callback.call()
		return
	
	if not points.valid_score:
		footer.text += "Hey buddy, you kinda cheated\nthere so no score saving alright?"
	
	header.text = header.text \
	.replace("{song}", PlayField.song_data.name) \
	.replace("{diff}", PlayField.play_manager.difficulty.to_upper())
	
	update_judgement_stuff()
	update_score_stuff()

func _unhandled_key_input(_e: InputEvent):
	if Input.is_action_just_pressed("ui_accept"):
		if close_callback != null: close_callback.call()

func update_judgement_stuff():
	judgement_info.text = ""
	var info_stuff: String = ""
	var loop_val: int = 0
	for i: String in Highscore.judgements.keys():
		info_stuff += "%s:%s" % [
			i.to_pascal_case(),
			str(points.judgements_hit[loop_val])
		]
		if loop_val != Highscore.judgements.keys().size()-1:
			info_stuff += "\n"
		else:
			info_stuff += "\n\n"
		loop_val += 1
	
	info_stuff += "Misses:%s" % points.misses
	if not Settings.ghost_tapping:
		info_stuff += "\nGhost Taps:%s" % points.ghost_taps
		info_stuff += "\nTotal Misses:%s" % [points.misses + points.ghost_taps]
	
	judgement_info.text = info_stuff

func update_score_stuff():
	note_info.text = ""
	var eval: String = points.current_evaluation
	if eval.is_empty(): eval = "F"
	
	var cool_note: String = "Score:%s" % points.score
	cool_note += "\nHits:%s/%s" % [points.total_notes_hit, PlayField.chart.notes.size()]
	cool_note += "\nAccuracy:%s" % points.accuracy_to_str()
	cool_note += "\nEvaluation:%s" % eval
	note_info.text = cool_note
