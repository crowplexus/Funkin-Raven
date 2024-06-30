extends RefCounted
class_name Scoring

const TEMPLATE_HIT_SCORE: Dictionary = {
	"score": 0,
	"accuracy": 0.0,
	"total_notes_hit": 0,
	"health": 0,
	"combo": 0,
}

const DOIDO_MIN_SCORE: int = 0.0
const DOIDO_MAX_SCORE: int = 500
const DOIDO_SCORE_SLOPE: float = 5.0
const HIT_THRESHOLD: float = 200.0

const JUDGMENTS: Dictionary = {
	"perfect": {
		"splash": true, "combo_break": false,
		"accuracy": 100.0, "threshold": 5.0,
		"color": Color("ff89c9"),
		"clear": { "full": "PFC" },
		"visible": false, # hides judgment sprite
	},
	"epic": {
		"splash": true, "combo_break": false,
		"accuracy": 100.0, "threshold": 22.5,
		"color": Color("ff89c9"),
		"clear": { "full": "EFC" },
		"visible": true,
	},
	"sick": {
		"splash": true, "combo_break": false,
		"accuracy": 90.0, "threshold": 45.0,
		"color": Color("626592"),
		"clear": { "single": "SDS", "full": "SFC" },
		"visible": true,
	},
	"good": {
		"splash": false, "combo_break": false,
		"accuracy": 85.0, "threshold": 90.0,
		"color": Color("77d0c1"),
		"clear": { "single": "SDG", "full": "GFC" },
		"visible": true,
	},
	"bad": {
		"splash": false, "combo_break": true,
		"accuracy": 30.0, "threshold": 135.0,
		"color": Color("f7433f"),
		"clear": { "full": "FC" },
		"visible": true,
	},
	"shit": {
		"splash": false, "combo_break": true,
		"accuracy": 0.0, "threshold": 180.0,
		"color": Color("e5af32"),
		"clear": { "full": "FC" },
		"visible": true,
	},
	"miss": {
		"splash": false, "combo_break": false,
		"accuracy": 0.0, "threshold": HIT_THRESHOLD,
		"color": Color.CRIMSON,
		"clear": { "full": "" }, # it isn't lol
		"visible": false,
	},
}

static func get_doido_score(x: float) -> int:
	# https://github.com/DiogoTVV/FNF-Doido-Engine-3
	# https://github.com/DiogoTVV/FNF-Doido-Engine-3
	# https://github.com/DiogoTVV/FNF-Doido-Engine-3
	# THANKS DIOGO!!!!!! PLEASE CHECK OUT HIS PROJECT :3
	var score: int = remap(x, DOIDO_MIN_SCORE, DOIDO_MAX_SCORE, JUDGMENTS.shit.threshold, DOIDO_SCORE_SLOPE)
	return clampi(score, DOIDO_MIN_SCORE, DOIDO_MAX_SCORE)


static func get_wife_score(max_millis: float, version: int = 3, ts: float = -1.0) -> float:
	if ts < 0.0: ts = AudioServer.playback_speed_scale
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
	if JUDGMENTS.has(name):
		return JUDGMENTS[name]
	return JUDGMENTS.shit


static func get_clear_flag(hit_reg: Dictionary) -> String:
	if hit_reg.shit > 0:
		return JUDGMENTS.shit.clear.full
	elif hit_reg.bad > 0:
		return JUDGMENTS.bad.clear.full
	elif hit_reg.good > 0:
		if hit_reg.good < 10: return JUDGMENTS.good.clear.single
		else: return JUDGMENTS.good.clear.full
	elif hit_reg.sick > 0:
		if hit_reg.sick < 10 and Preferences.use_epics: return JUDGMENTS.sick.clear.single
		else: return JUDGMENTS.sick.clear.full
	elif hit_reg.epic > 0:
		return JUDGMENTS.epic.clear.full
	return ""


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
		"SDCB":
			return Color.IVORY
	return Color.WHITE


static func judge_note(note: Note, fallback_diff: float = 0.0) -> Dictionary:
	match note.kind:
		_:
			var result = null
			if note.object and note.object.has_meta("judge_note"):
				result = note.object.call_deferred("judge_note", note)
			if result == null or not result is Dictionary:
				result = judge_time(fallback_diff)
			return result


static func judge_time(millisecond_time: float) -> Dictionary:
	# this is faster than a for loop but less convenient
	# at this moment i'm aiming for performance.
	match millisecond_time:
		# -- example --
		# _ when millisecond_time <= JUDGEMENTS.my_custom_judge.threshold:
		#	return JUDGMENTS.my_custom_judge
		_ when millisecond_time <= JUDGMENTS.epic.threshold and Preferences.use_epics:
			return JUDGMENTS.epic
		_ when millisecond_time <= JUDGMENTS.sick.threshold:
			return JUDGMENTS.sick
		_ when millisecond_time <= JUDGMENTS.good.threshold:
			return JUDGMENTS.good
		_ when millisecond_time <= JUDGMENTS.bad.threshold:
			return JUDGMENTS.bad
		_ when millisecond_time <= JUDGMENTS.shit.threshold:
			return JUDGMENTS.shit
		_: # Default Judgment.
			return JUDGMENTS.miss
