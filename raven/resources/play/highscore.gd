class_name Highscore extends Node

const JUDGE_DIFFS: Array = [
	#	Epic	Sick	Good	Bad		Shit
	[22.5,	45.0,	90.0,	135.0,	180.0], # Judge Four
	[18.9,	37.8,	75.6,	113.4,	151.0], # Judge Five (Default)
	[22.0,	43.0,	102.0,	135.0,	180.0], # Not in the Groove
	[18.36,	33.33,	91.67,	133.33,	166.67], # Funkin
	[18.0,	39.0,	102.0,	127.0,	164.0], # Freestyle Standard
]

static var judge_diff: int = 1

static var judgements: Dictionary = {
	#		Score		Timing,									Accuracy,	Note Splash,	Color
	"epic": [350,		JUDGE_DIFFS[judge_diff][0] * 0.001,		100.0,		true,			Color("#7B79C2")],
	"sick": [250,		JUDGE_DIFFS[judge_diff][1] * 0.001,		95.0,		false,			Color("#ACE7FF")],
	"good": [200,		JUDGE_DIFFS[judge_diff][2] * 0.001,		85.0,		false,			Color("#BFFCC6")],
	"bad":  [100,		JUDGE_DIFFS[judge_diff][3] * 0.001,		50.0,		false,			Color("#FFFFFF")], # kinda already has a color so i left it out
	"shit": [ 50,		JUDGE_DIFFS[judge_diff][4] * 0.001,		0.0,		false,			Color("#FFBEBC")],
}

static func get_timings_difficulty(diff: int = 1) -> Array:
	if diff < 0 or diff > JUDGE_DIFFS.size():
		diff = 1
		push_warning("Invalid Judgement Difficulty (",diff,"), using default (5)")
	return JUDGE_DIFFS[diff]

static func best_judgement() -> Array:
	return Highscore.judgements[Highscore.judgements.keys().front()]

static func worst_judgement() -> Array:
	return Highscore.judgements[Highscore.judgements.keys().back()]

static func judgement_from_time(time: float) -> String:
	var judged: String = judgements.keys().back()
	
	for i in judgements.keys():
		if time > judgements[i][1]:
			continue
		
		elif judgements[i][1] != NAN:
			judged = i
			break
		
	return judged

static func save_performance_stats(data: Dictionary, song: String, diff: String = "normal"):
	if get_performance_stats(song, diff).score > data.score:
		return
	
	var conf: = ConfigFile.new()
	
	# TODO: ENCRYPT THIS LATER :3
	conf.load("user://highscore.cfg")
	conf.set_value(diff, song, data)
	conf.save("user://highscore.cfg")
	
	conf.clear()
	conf.unreference()

static func get_performance_stats(song: String, diff: String = "normal"):
	var value: Dictionary = ScoreManager.get_default_performance()
	var conf: = ConfigFile.new()
	conf.load("user://highscore.cfg")
	value = conf.get_value(diff, song, ScoreManager.get_default_performance())
	# old dev values #
	if not value.has("misses"):
		value["misses"] = 0
	
	if not value.has("evaluation"):
		if value.has("grade"): 
			value["evaluation"] = value["grade"]
			value.erase("grade")
		else:
			value["evaluation"] = "N/A"
	
	conf.unreference()
	return value
