extends Control

@onready var panel: Panel = $"panel"
@onready var header: Label = $"panel/header"
@onready var footer: Label = $"panel/footer"
@onready var judgement_info: Label = $"panel/judgement_stuff"
@onready var note_info: Label = $"panel/judgement_stuff/note_stuff"

var close_callback: Callable = func() -> void:
	Tools.switch_scene(load("res://raven/menu/main_menu.tscn"))

var stats: Scoring

func _ready() -> void:
	if PlayField.play_manager != null:
		stats = PlayField.play_manager.stats

	if PlayField.chart == null or stats == null:
		close_callback.call()
		return

	header.text = header.text.replace("SONG CLEARED", tr("eval_song_cleared"))
	footer.text = tr("eval_leave") + "\n"
	if not stats.valid_score:
		footer.text += tr("eval_cheated") + "\n"

	header.text = header.text \
	.replace("{song}", PlayField.song_data.name) \
	.replace("{diff}", tr(PlayField.play_manager.difficulty).to_upper())

	update_judgement_stuff()
	update_score_stuff()

func _unhandled_input(_e: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		close_callback.call()

func update_judgement_stuff() -> void:
	judgement_info.text = ""
	var info_stuff: String = ""
	var loop_val: int = 0
	for i: Dictionary in Highscore.judgements:
		info_stuff += "%s:%s" % [
			tr("judgement_" + i.name),
			str(stats.judgements_hit[loop_val])
		]
		if loop_val != Highscore.judgements.size() - 1:
			info_stuff += "\n"
		else:
			info_stuff += "\n\n"
		loop_val += 1

	info_stuff += tr("info_misses") + ":%s" % stats.misses
	if not Settings.ghost_tapping:
		info_stuff += "\n" + tr("info_ghost_taps") + ":%s" % stats.ghost_taps
		info_stuff += "\n" + tr("info_total_misses") + ":%s" % [stats.misses + stats.ghost_taps]

	judgement_info.text = info_stuff

func update_score_stuff() -> void:
	note_info.text = ""
	var eval: String = stats.current_grade
	if eval.is_empty(): eval = "F"

	var cool_note: String = tr("info_score") + ":%s" % stats.score
	cool_note += "\n" + tr("info_hits") + ":%s/%s" % [stats.total_notes_hit, stats.total_notes]
	cool_note += "\n" + tr("info_accuracy") + ":%s" % stats.accuracy_to_str()
	cool_note += "\n" + tr("info_grade") + ":%s" % eval
	cool_note += "\n" + tr("info_clear_flag") + ":%s" % stats.get_clear_flag()
	note_info.text = cool_note
