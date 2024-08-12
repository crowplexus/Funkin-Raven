extends RefCounted
class_name Scoring

# DiogoTV scoring system
const DOIDO_MIN_SCORE: int = 0
const DOIDO_MAX_SCORE: int = 500
const DOIDO_SCORE_SLOPE: float = 5.0

const HIT_THRESHOLD: float = 200.0
const JUDGMENTS: Dictionary = {
	"perfect": {
		## NOTE: this can only be hit by a bot,
		## If you wanna use this, make sure to disable the
		## cheating checks on [code]PlayerStats[/code]
		"splash": true, "combo_break": false,
		"accuracy": 100.0, "color": Color("ff89c9"),
		"clear": { "full": "PFC" },
		"visible": false, # hides judgment sprite
	},
	"epic": {
		"splash": true, "combo_break": false,
		"accuracy": 100.0, "color": Color("ff89c9"),
		"clear": { "full": "EFC" },
		"visible": true,
	},
	"sick": {
		"splash": true, "combo_break": false,
		"accuracy": 90.0, "color": Color("626592"),
		"clear": { "single": "SDS", "full": "SFC" },
		"visible": true,
	},
	"good": {
		"splash": false, "combo_break": false,
		"accuracy": 85.0, "color": Color("77d0c1"),
		"clear": { "single": "SDG", "full": "GFC" },
		"visible": true,
	},
	"bad": {
		"splash": false, "combo_break": true,
		"accuracy": 30.0, "color": Color("f7433f"),
		"clear": { "full": "FC" },
		"visible": true,
	},
	"shit": {
		"splash": false, "combo_break": true,
		"accuracy": 0.0, "color": Color("e5af32"),
		"clear": { "full": "FC" },
		"visible": true,
	},
	"miss": {
		# this is a fake judgement only used as placeholder
		"splash": false, "combo_break": false,
		"accuracy": 0.0, "color": Color.CRIMSON,
		"clear": { "full": "" }, # it isn't lol
		"visible": false,
	},
}
const HITTABLE_JUDGES: PackedStringArray = ["epic", "sick", "good", "bad", "shit"]

const JUDGE_TIMINGS: Dictionary = {
	# Order: Epic, Sick, Good, Bad, Shit
	# Etterna Difficulties - https://docs.google.com/spreadsheets/d/1syi5aN6sTiDA2Bs_lzZjsLQ1yCEhxl5EnAd6EsD6cF4/edit#gid=0
	"J1": [33.75, 67.5, 135.0, 202.5, 270.0],
	"J2": [29.925, 59.85, 119.7, 179.55, 239.4],
	"J3": [26.1, 52.2, 104.4, 156.6],
	"J4": [22.5, 45.0, 90.0, 135.0, 180.0],
	"J5": [18.9, 37.8, 75.6, 133.4, 180.0],
	"J6": [14.85, 29.7, 59.4, 89.1, 180.0],
	"J7": [11.25, 22.5, 45.0, 67.5, 180.0],
	"J8": [7.425, 14.85, 29.7, 44.55, 180.0],
	"JUSTICE": [4.5, 9.0, 18.0, 27.0, 180.0], # AKA J9
	# Other Difficulties
	"EQUITY": [1.0, 5.0, 10.5, 25.0, 180.0], # J10 wannabe
	"WEEK7": [NAN, 33.33, 125.0, 150.0, 166.67], # Old FNF	, Disables Epic
	# these are from here: https://itgwiki.dominick.cc/en/software/stepmania-judgements
	"ITG": [23.0, 44.5, 103.5, 136.5, 181.5], # ITG/FA+ (minus blue fantastic window)
	"DDR": [16.67, 33.33, 83.33, 123.33, 163.33], # DDR
	#--------------------------------------------
	#"CUSTOM": [NAN, NAN, NAN, NAN, NAN], # Custom timings
}

static func judge_time(millisecond_time: float) -> Dictionary:
	var thresholds: Array = Scoring.JUDGE_TIMINGS[Preferences.timing_diff]
	var can_epic: bool = Preferences.use_epics and Preferences.timing_diff != "WEEK7"
	for i: int in thresholds.size():
		var judge: StringName = JUDGMENTS.keys()[i]
		if not HITTABLE_JUDGES.has(judge): continue
		if judge == "epic" and not can_epic: continue
		if millisecond_time <= thresholds[i] and thresholds[i] != NAN:
			return JUDGMENTS[judge]
	return JUDGMENTS.miss

static func get_doido_score(x: float) -> 	int:
	# https://github.com/DiogoTVV/FNF-Doido-Engine-3
	# https://github.com/DiogoTVV/FNF-Doido-Engine-3
	# https://github.com/DiogoTVV/FNF-Doido-Engine-3
	# THANKS DIOGO!!!!!! PLEASE CHECK OUT HIS PROJECT :3
	var boo_threshold: float = Scoring.JUDGE_TIMINGS[Preferences.timing_diff].back()
	var score: float = remap(x, DOIDO_MIN_SCORE, DOIDO_MAX_SCORE, boo_threshold, DOIDO_SCORE_SLOPE)
	return clampi(floori(score), DOIDO_MIN_SCORE, DOIDO_MAX_SCORE)

static func get_wife_score(max_millis: float, version: int = 3, ts: float = -1.0) -> float:
	if ts < 0.0: ts = AudioServer.	playback_speed_scale
	var score: float = 0
	match version:
		3:
			var werwerwerf: Callable = func(x: float):
				var a1: float = 0.254829592
				var a2: float = -0.284496736
				var a3: float = 1.421413741
				var a4: float = -1.453152027
				var a5: float = 1.061405429
				var p: float = 0.3275911
				var xs: float = sign(x)
				x = abs(x)
				var t: float = 1.0 / (1.0 + p * x)
				var y: float = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x)
				return xs * y

			var j_pow: float = 0.75
			var ridic: float = 5.0 * ts
			var absolute_max_ms: float = absf(max_millis * 1000.0)
			var wife3_max_points: float = 2.0
			var wife3_max_boo_weight: float = 180.0 * ts
			var wife3_miss_weight: float = -5.5
			if absolute_max_ms <= ridic:
				return wife3_max_points

			var zero: float = 65.0 * pow(ts, j_pow)
			var dev:  float = 22.7 * pow(ts, j_pow)
			if max_millis <= zero:
				score = wife3_max_points * werwerwerf.call((zero-max_millis)/dev)
			if max_millis <= wife3_max_boo_weight:
				score = (max_millis-zero)*wife3_miss_weight/(wife3_max_boo_weight-zero)
			score = wife3_miss_weight
	return score

static func get_judge_by_name(name: StringName) -> Dictionary:
	if JUDGMENTS.has(name): return JUDGMENTS[name]
	return JUDGMENTS.miss

static func get_clear_flag(hit_reg: Dictionary, simple: bool = false) -> String:
	var cf: String = ""
	if hit_reg.shit > 0:
		cf = JUDGMENTS.shit.clear.full
	elif hit_reg.bad > 0:
		cf = JUDGMENTS.bad.clear.full
	elif hit_reg.good > 0:
		if not simple:
			if hit_reg.good < 10: cf = JUDGMENTS.good.clear.single
			else: cf = JUDGMENTS.good.clear.full
			if Preferences.use_epics and hit_reg.good == 1:
				cf = "BF" # black flag if we can
		else:
			cf = JUDGMENTS.good.clear.full
	elif hit_reg.sick > 0:
		if not simple:
			if Preferences.use_epics: # sick is not highest judge
				if hit_reg.sick == 1: cf = "WF"
				elif hit_reg.sick < 10: cf = JUDGMENTS.sick.clear.single
				else: cf = JUDGMENTS.sick.clear.full
			else: cf = JUDGMENTS.sick.clear.full
		else:
			cf = JUDGMENTS.sick.clear.full
	elif hit_reg.epic > 0:
		cf = JUDGMENTS.epic.clear.full
	return cf

static func get_clear_flag_color(flag: String) -> Color:
	match flag:
		JUDGMENTS.epic.clear.full:
			return Color.MEDIUM_PURPLE
		JUDGMENTS.sick.clear.full, JUDGMENTS.sick.clear.single:
			return Color.ROYAL_BLUE
		JUDGMENTS.good.clear.full, JUDGMENTS.good.clear.single:
			return Color.SPRING_GREEN
		JUDGMENTS.bad.clear.full, JUDGMENTS.shit.clear.full:
			return Color.LIGHT_CORAL
		"WF": return Color.BURLYWOOD
		"BF": return Color.CHOCOLATE
	return Color.WHITE

static func get_judgement_colour(judge_name: StringName) -> Color:
	if judge_name in JUDGMENTS:
		if "colour" in JUDGMENTS[judge_name]:
			return JUDGMENTS[judge_name].colour
		if "color" in JUDGMENTS[judge_name]:
			return JUDGMENTS[judge_name].color
	return Color.WHITE

static func judge_note(note: Note, fallback_diff: float = 0.0) -> Dictionary:
	match note.kind:
		_:
			var result = null
			#if note and note.object and note.object.has_meta("judge_note"):
			#	result = note.object.call_deferred("judge_note", note)
			if result == null or not result is Dictionary:
				result = judge_time(fallback_diff)
			return result
