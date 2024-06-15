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
const JUDGMENTS: Array[Dictionary] = [
	{
		"name": "epic", "splash": true,
		"accuracy": 100.0, "threshold": 22.5,
		"color": Color("ff89c9"),
		"clear": { "full": "EFC" },
		"combo_break": false,
	},
	{
		"name": "sick", "splash": true,
		"accuracy": 90.0, "threshold": 45.0,
		"color": Color("626592"),
		"clear": { "single": "SDS", "full": "SFC" },
		"combo_break": false,
	},
	{
		"name": "good", "splash": false,
		"accuracy": 85.0, "threshold": 90.0,
		"color": Color("77d0c1"),
		"clear": { "single": "SDG", "full": "GFC" },
		"combo_break": false,
	},
	{
		"name": "bad", "splash": false,
		"accuracy": 30.0, "threshold": 135.0,
		"color": Color("f7433f"),
		"clear": { "full": "FC" },
		"combo_break": true,
	},
	{
		"name": "shit", "splash": false,
		"accuracy": 0.0, "threshold": 180.0,
		"color": Color("e5af32"),
		"clear": { "full": "FC" },
		"combo_break": true,
	},
	#{
	#	"name": "miss", "splash": false,
	#	"accuracy": 0.0, "threshold": NAN,
	#	"color": Color.DIM_GRAY,
	#},
]


static func get_clear_flag(hit_reg: Dictionary) -> String:
	var flag: String = ""
	for judge: Dictionary in JUDGMENTS:
		if not "clear" in judge: continue
		if judge.name in hit_reg and hit_reg[judge.name] > 0:
			var _idx: int = JUDGMENTS.find(judge)
			#if idx == 1 and hit_reg[judge.name] == 1: flag = "WF"
			#elif idx == 2 and hit_reg[judge.name] == 1: flag = "BF"
			if hit_reg[judge.name] < 10 and "single" in judge.clear:
				flag = judge.clear.single
			else:
				flag = judge.clear.full
	return flag


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
	var result: Dictionary = Scoring.JUDGMENTS.back()
	for i: int in JUDGMENTS.size():
		var judgment: Dictionary = Scoring.JUDGMENTS[i]
		if judgment.threshold == NAN:
			continue

		if millisecond_time <= judgment.threshold:
			result = judgment
			break
	return result
