class_name Highscore extends Node

const TIMING_PRESETS: Array = [
	#	Epic	Sick	Good	Bad		Shit
	[22.5,	45.0,	90.0,	135.0,	180.0], # Judge Four
	[18.9,	37.8,	75.6,	113.4,	151.0], # Judge Five (Default)
	[22.0,	43.0,	102.0,	135.0,	180.0], # Not in the Groove
	[18.36,	33.33,	91.67,	133.33,	166.67], # Funkin (WEEK 7)
	[12.5,	45.0,	90.0,	135.0,	160.0], # Funkin (NEW PBOT1)
	[18.0,	39.0,	102.0,	127.0,	164.0], # Freestyle Standard
]

static var judge_diff: int = 1
static var judgements: Array[Dictionary] = []
static var timings: Array[float] = []

static func _reset_judgements() -> void:
	var sick_accuracy: float = 95.0 if Settings.use_epics else 100.0
	Highscore.judgements = [
		{"name": "epic", "accuracy": 100.0,			"color": Color("ff89c9"),			"splash": true},
		{"name": "sick", "accuracy": sick_accuracy, "color": Color("626592"),			"splash": true},
		{"name": "good", "accuracy": 85.0,			"color": Color("77d0c1"),			"splash": false},
		{"name": "bad",  "accuracy": 50.0,			"color": Color("f7433f"),			"splash": false},
		{"name": "shit", "accuracy":  0.0,			"color": Color("e5af32"),			"splash": false},
	]

	if Settings.timings.size() < Highscore.judgements.size():
		Settings.timings = []
		Settings.timings.append_array(Highscore.TIMING_PRESETS[Highscore.judge_diff])

	Highscore.timings = []
	Highscore.timings.append_array(Settings.timings)

	for i: int in Highscore.judgements.size():
		var timing: float = timings[i] * 0.001
		if not Settings.use_epics and i == 0:
			timing = -1
		Highscore.judgements[i]["timing"] = timing

static func best_judgement() -> Dictionary:
	var i: int = 0 if Settings.use_epics else 1
	return Highscore.judgements[i]

static func worst_judgement() -> Dictionary:
	return Highscore.judgements.back()

static func save_performance_stats(data: Dictionary, song: String, diff: String = "normal") -> void:
	var conf: = ConfigFile.new() as ConfigFile

	conf.load("user://player_scores.cfg")
	if conf.has_section_key(diff, song):
		data["attempt"] = conf.get_value(diff, song)["attempt"] + 1

	conf.set_value(diff, song, data)
	conf.save("user://player_scores.cfg")

	conf.clear()
	conf.unreference()

static func get_performance_stats(song: String, diff: String = "normal") -> Dictionary:
	var value: Dictionary = Highscore.get_default_performance()
	var conf: = ConfigFile.new()
	conf.load("user://player_scores.cfg")
	value = conf.get_value(diff, song, Highscore.get_default_performance())
	conf.unreference()
	return value

static func get_default_performance() -> Dictionary:
	return {
		"score": 0, "accuracy": 0.0, "misses": 0, "grade": "N/A",
		"calculator": Settings.accuracy_calculator,
		"timings": Highscore.timings,
		"player": 2 if Settings.enemy_play else 1, "attempt": 0
	}
