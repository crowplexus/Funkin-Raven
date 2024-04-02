extends OptionsBar

var og_desc: String
func _ready():
	og_desc = description
	super()

func update_setting(amnt: int = 0, precache: bool = false):
	super(amnt, precache)
	description = og_desc + "\n\n"
	for i: int in Highscore.judgements.keys().size():
		var judge: String = Highscore.judgements.keys()[i].to_upper()
		description += "%s: %sms" % [
			judge, Highscore.JUDGE_DIFFS[Settings.judgement_difficulty][i],
		]
		if i != Highscore.judgements.keys().size()-1:
			description += " | "
	if not precache:
		$'../../../../'.update_desc()
