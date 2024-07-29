extends OptionItem

func _ready() -> void:
	# i don't wanna have to set these manually ffs
	display_names = []
	display_names.append_array(Scoring.JUDGE_TIMINGS.keys())
	super()
