class_name Scoring extends Node

#region Statics and Constants, mostly used for scoring

const GRADES: Dictionary = {
	# 🐍
	"SSSS": 100, "SSS": 99.45,
	"SS": 98.25, "S": 97.0,
	# other grades
	"A+": 96.5, "A": 95.0,
	"B+": 90.0, "B": 85.0,
	"C+": 80.0, "C": 70.0,
	"D+": 65.0, "D": 60.0,
}

const WIFE3_MISS_WEIGHT: float = -5.5

static func judge_time(time: float) -> int:
	var judged: int = Highscore.judgements.find(Highscore.judgements.back())
	for i: int in Highscore.judgements.size():
		var judgement: Dictionary = Highscore.judgements[i]
		if time > judgement.timing or judgement.timing == -1:
			continue
		else:
			judged = i
			break

	return judged

static func get_judgement_accuracy(judgement_idx: int) -> float:
	return maxf(Highscore.judgements[judgement_idx].accuracy, 0)

# STUFF FROM ETTERNA
# WIFE3 IS GREAT AAA
# https://github.com/etternagame/etterna/blob/9a0b9fb94ea0c1f4d24b707bd00fad24d94d22ec/src/RageUtil/Utils/RageUtil.h#L121 ####
# I HADLY KNOW WHAT ANY OF THIS MEANS AND
# SHOULD PROBABLY STUDY IT, THANKS ETTERNA
# WILL LEAVE THE COMMENTS FROM THE ORIGINAL HERE TOO

# erf approximation A&S formula 7.1.26
static func werwerwerwerf(x: float) -> float:
	var a1: float = 0.254829592
	var a2: float = -0.284496736
	var a3: float = 1.421413741
	var a4: float = -1.453152027
	var a5: float = 1.061405429
	var p: float = 0.3275911
	x = absf(x)

	var t: float = 1.0 / (1.0 + p * x)
	var y: float = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x)
	return signf(x) * y

static func get_wife3_accuracy(maxms: float, ts: float = -1.0) -> float:
	if ts == -1.0: ts = Engine.time_scale
	if ts > 1.0: ts = 1.0
	var j_pow: float = 0.75 # so judge scaling isn't so extreme
	var max_points: float = 100.0 # min/max points
	var ridic: float = 5.0 * ts # offset at which points starts decreasing(ms)
	var max_boo_weight: float = Highscore.worst_judgement().timing

	# piecewise inflection
	var zero: float = 65.0 * pow(ts, j_pow)
	var dev: float  = 22.7 * pow(ts, j_pow)
	# need positive values for this
	maxms = absf(maxms)
	# case optimizations
	if maxms <= ridic:
		return max_points
	elif maxms <= zero:
		return max_points * Scoring.werwerwerwerf((zero - maxms)/dev)
	elif maxms <= max_boo_weight:
		return (maxms-zero) * WIFE3_MISS_WEIGHT/(max_boo_weight-zero)
	return WIFE3_MISS_WEIGHT

#endregion

var score: int = 0
var misses: int = 0
var ghost_taps: int = 0
var combo: int = 0
## "But what is, a Combo Break" you may ask?[br]
## I hired this yellow rubber duck to explain to you what a combo break is.[br][br]
## https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTI0UIE6GMcHkWEcJpOnrKtkNuOF92KeSxq8heIxERW7w&s[br]
## "a Combo Break is when you have more than 1 note hits in a sequence[br]
## and then you miss a note, thus 'Breaking' the Combo.[br][br]
## Combo Breaks also happen if you get judgements that are considered really bad!"
var breaks: int = 0

var accuracy: float:
	get:
		var v: float = 0.0
		if total_notes_hit != 0:
			# 0: Common | 1: ITG
			match Settings.accuracy_display_style:
				0: v = total_played / (total_notes_hit + misses)
				1: v = (total_played / total_notes) - misses
		return absf(v)

var judgements_hit: Array[int] = []
var valid_score: bool = true
var current_grade: String:
	get:
		var ret :String = "" # Not Applicable.
		if valid_score and total_notes_hit != 0:
			var grade_score: float = snappedf(accuracy, 0.01)
			for i: String in GRADES.keys():
				if grade_score >= GRADES[i]:
					ret = i
					break
		return ret

var stored_time: float = 0.0
var total_notes_hit: int = 0
var total_played: float = 0.0
var total_notes: int = 0

func _init() -> void:
	reset_all()

func update_hits(judge: int, by: int = 1) -> void:
	judgements_hit[judge] += by

func update_accuracy(judgement_idx: int, note_secs: float) -> void:
	# separated these into functions for consistency
	match Settings.accuracy_calculator:
		0: # Judgement-based
			total_played += Scoring.get_judgement_accuracy(judgement_idx)
		1: # Timing-based
			total_played += Scoring.get_wife3_accuracy(note_secs * 1000.0)
	total_notes_hit += 1

func accuracy_to_str() -> String:
	return str( snappedf(accuracy, 0.01) ) + "%"

func reset_all() -> void:
	_reset_judgements()
	score = 0
	misses = 0
	breaks = 0
	total_played = 0
	total_notes_hit = 0
	total_notes = 0
	valid_score = true
	ghost_taps = 0
	combo = 0

func _reset_judgements() -> void:
	Highscore._reset_judgements()
	judgements_hit.clear()
	judgements_hit.resize(Highscore.judgements.size())
	judgements_hit.fill(0)

func get_performance() -> Dictionary:
	var perf: Dictionary = Highscore.get_default_performance()
	if (perf.calculator == Settings.accuracy_calculator
			and perf.timings == Highscore.timings
			and perf.player == 1 if Settings.enemy_play else 2):
		perf.score = score
		perf.misses = misses
		perf.accuracy = snappedf(accuracy, 0.01)
		perf.grade = current_grade if not current_grade.is_empty() else "Fail"
	return perf

func get_clear_flag() -> StringName:
	var clear_flag: StringName = ""
	if total_notes_hit == 0:
		return tr("flag_noplay")

	var epics: int = judgements_hit[0]
	var sicks: int = judgements_hit[1]
	var goods: int = judgements_hit[2]

	if breaks <= 0:
		# lowest to highest
		if goods > 1:
			if goods < 10: clear_flag = tr("flag_good_sd")
			else: clear_flag = tr("flag_good_fc")
		elif sicks > 1:
			clear_flag = tr("flag_sick_fc") # Sick Full Combo
			if Settings.use_epics: # SD and BF checks happen if this is *not* the highest judgement.
				if goods == 1: clear_flag = tr("flag_black") # Black Flag (SFC ruined by a single good)
				elif sicks < 10: clear_flag = tr("flag_sick_sd") # Single Digit Sick
		elif epics > 0:
			if sicks == 1: clear_flag = tr("flag_white") # White Flag (EFC ruined by a single sick)
			else: clear_flag = tr("flag_epic_fc") # Epic Full Combo

		else: # Bads, Shits
			clear_flag = tr("flag_full_combo")
	else:
		if breaks == 1: clear_flag = tr("flag_miss") # Miss Flag (FC broken by 1 combo break)
		elif breaks < 10: clear_flag = tr("flag_combo_break_sd") # Single Digit Combo Break
		else: clear_flag = tr("flag_clear")

	return clear_flag

