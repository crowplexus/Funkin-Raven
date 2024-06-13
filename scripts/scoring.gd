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
		"clear": { "single": "SDE", "full": "EFC" },
	},
	{
		"name": "sick", "splash": true,
		"accuracy": 90.0, "threshold": 45.0,
		"color": Color("626592"),
		"clear": { "single": "SDS", "full": "SFC" },
	},
	{
		"name": "good", "splash": false,
		"accuracy": 85.0, "threshold": 90.0,
		"color": Color("77d0c1"),
		"clear": { "single": "SDG", "full": "GFC" }
	},
	{
		"name": "bad", "splash": false,
		"accuracy": 30.0, "threshold": 135.0,
		"color": Color("f7433f"),
		"clear": { "single": "SDB", "full": "FC" }
	},
	{
		"name": "shit", "splash": false,
		"accuracy": 0.0, "threshold": 180.0,
		"color": Color("e5af32"),
		"clear": { "single": "SD", "full": "FC" }
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
			var idx: int = JUDGMENTS.find(judge)
			if idx == 1 and hit_reg[judge.name] == 1: flag = "WF"
			elif idx == 2 and hit_reg[judge.name] == 1: flag = "BF"
			elif hit_reg[judge.name] < 10:
				flag = judge.clear.single
			else:
				flag = judge.clear.full
	return flag

static func judge_note(millisecond_time: float, note: Note) -> Dictionary:
	var result: Dictionary = Scoring.JUDGMENTS.back()

	match note.kind:
		_:
			for i: int in JUDGMENTS.size():
				var judgment: Dictionary = Scoring.JUDGMENTS[i]
				if judgment.threshold == NAN:
					continue

				if millisecond_time <= judgment.threshold:
					result = judgment
					break

	return result
