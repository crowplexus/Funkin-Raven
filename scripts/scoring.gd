extends RefCounted
class_name Scoring

const TEMPLATE_HIT_SCORE: Dictionary = {
	"score": 0,
	"accuracy": 0.0,
	"total_notes_hit": 0,
	"health": 0,
	"combo": 0,
}

const MAX_SCORE: int = 500
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

static func get_judge_by_name(name: StringName) -> Dictionary:
	if JUDGMENTS.has(name):
		return JUDGMENTS[name]
	return JUDGMENTS.shit


static func get_clear_flag(hit_reg: Dictionary) -> String:
	if hit_reg.breaks > 0:
		return "SDCB" if hit_reg.breaks < 10 else ""
	elif hit_reg.shit > 0:
		return JUDGMENTS.shit.clear.full
	elif hit_reg.bad > 0:
		return JUDGMENTS.bad.clear.full
	elif hit_reg.good > 0:
		if hit_reg.good < 10: return JUDGMENTS.good.clear.single
		else: return JUDGMENTS.good.clear.full
	elif hit_reg.sick > 0:
		if hit_reg.sick < 10: return JUDGMENTS.sick.clear.single
		else: return JUDGMENTS.sick.clear.full
	elif hit_reg.epic > 0:
		return JUDGMENTS.epic.clear.full
	return ""


static func get_clear_flag_color(flag: String) -> Color:
	match flag:
		JUDGMENTS.epic.clear.full:
			Color.MEDIUM_PURPLE
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
			if is_instance_valid(note.object) and note.object.has_meta("judge_note"):
				result = note.object.call_deferred("judge_note", note)
			if result == null or not result is Dictionary:
				result = judge_time(fallback_diff)
			return result


static func judge_time(millisecond_time: float) -> Dictionary:
	# this is faster than a for loop but less convenient
	# at this moment i'm aiming for performance.
	match millisecond_time:
		_ when millisecond_time <= JUDGMENTS.epic.threshold:
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
