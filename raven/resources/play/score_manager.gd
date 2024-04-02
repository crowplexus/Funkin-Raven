class_name ScoreManager extends Node

const EVALS: Dictionary = {
	# good luck.
	"SSSS": 100, "SSS": 99.4, "SS": 99.3,
	# evals that anyone can reach.
	"S": 95, "A": 90, "B": 80,
	"C": 70, "D": 60
}

var score: int = 0
var misses: int = 0
var ghost_taps: int = 0
var combo: int = 0

var accuracy: float:
	get:
		if total_notes_hit != 0:
			return absf(total_played / (total_notes_hit + misses))
		return 0.0

var judgements_hit: Array[int] = []
var valid_score: bool = true
var current_evaluation: String:
	get:
		if not valid_score: return tr("invalid_evaluation")
		var ret :String = "N/A" if total_notes_hit == 0 else ""
		if total_notes_hit != 0: for i in EVALS.keys():
			if EVALS[i] <= snappedf(accuracy, 0.01):
				ret = i; break
		return ret

var total_notes_hit: int = 0
var total_played: float = 0.0

func _init():
	reset_all()

func update_hits(judge: String, by: int = 1):
	judgements_hit[Highscore.judgements.keys().find(judge)] += by

func update_accuracy(total: float):
	total_played += total
	total_notes_hit += 1

func accuracy_to_str() -> String:
	return str( snappedf(accuracy, 0.01) )+"%"

func get_performance() -> Dictionary:
	var final_eval: String = current_evaluation
	if current_evaluation.is_empty():
		final_eval = "F"
	return {
		"score": score,
		"accuracy": snappedf(accuracy, 0.01),
		"misses": misses,
		"evaluation": final_eval
	}

func reset_all():
	score = 0
	misses = 0
	total_played = 0
	total_notes_hit = 0
	valid_score = true
	ghost_taps = 0
	combo = 0
	
	judgements_hit.clear()
	judgements_hit.resize(Highscore.judgements.keys().size())
	judgements_hit.fill(0)
	
	if Highscore.judge_diff != Settings.judgement_difficulty:
		Highscore.judge_diff = Settings.judgement_difficulty
		
		var ts: Array = Highscore.get_timings_difficulty(Settings.judgement_difficulty)
		for i: int in Highscore.judgements.keys().size():
			var key: StringName = Highscore.judgements.keys()[i]
			Highscore.judgements[key][1] = float(ts[i] * 0.001)

static func get_default_performance() -> Dictionary:
	return {"score": 0, "accuracy": 0.0, "misses": 0, "final_eval": "N/A"}
