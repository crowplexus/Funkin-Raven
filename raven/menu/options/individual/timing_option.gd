extends OptionsBar

@export var judgement: String = "miss"
var judgement_index: int = -1
var temp_timings: Array[float] = []

func _ready() -> void:
	temp_timings = Settings.timings
	for i: int in Highscore.judgements.size():
		if is_same(judgement, Highscore.judgements[i].name):
			judgement_index = i
			break
	set_timing(get_timing())

func _exit_tree() -> void:
	write_timing()

func update_setting(amnt: int = 0, precache: bool = false) -> void:
	if judgement_index == -1:
		val_name = "ERROR! No Judgement Set!"
		reload_value_name()
		return

	super(amnt, precache)

	if not precache:
		var shift_mult: float = 1.0 if not Input.is_key_pressed(KEY_SHIFT) else increment_rules[1]
		val = temp_timings[judgement_index] + (increment_rules[0] * shift_mult) * amnt
		temp_timings[judgement_index] = clampf(val, 0.0, 300)
		val = temp_timings[judgement_index]

	val_name = str(snappedf(val, 0.001))
	reload_value_name()

func get_timing() -> float:
	var timing: float = 0.00
	if judgement_index == -1:
		val_name = "ERROR! No Judgement Set!"
		reload_value_name()
		return timing
	timing = temp_timings[judgement_index]
	return timing

func set_timing(new_timing: float) -> void:
	var timing: float = 0.00
	if judgement_index == -1:
		val_name = "ERROR! No Judgement Set!"
		reload_value_name()
		return
	temp_timings[judgement_index] = new_timing
	val = get_timing()
	val_name = str(val)
	reload_value_name()

func write_timing() -> void:
	if judgement_index == -1:
		val_name = "ERROR! No Judgement Set!"
		reload_value_name()
		return

	Settings.timings[judgement_index] = temp_timings[judgement_index]
