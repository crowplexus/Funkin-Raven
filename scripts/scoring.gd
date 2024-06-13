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
	},
	{
		"name": "sick", "splash": true,
		"accuracy": 90.0, "threshold": 45.0,
		"color": Color("626592"),
	},
	{
		"name": "good", "splash": false,
		"accuracy": 85.0, "threshold": 90.0,
		"color": Color("77d0c1"),
	},
	{
		"name": "bad", "splash": false,
		"accuracy": 30.0, "threshold": 135.0,
		"color": Color("f7433f"),
	},
	{
		"name": "shit", "splash": false,
		"accuracy": 0.0, "threshold": 180.0,
		"color": Color("e5af32"),
	},
	{
		"name": "miss", "splash": false,
		"accuracy": 0.0, "threshold": NAN,
		"color": Color.DIM_GRAY,
	},
]


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
