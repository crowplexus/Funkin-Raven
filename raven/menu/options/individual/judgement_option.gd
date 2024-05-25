extends OptionsBar

func update_setting(amnt: int = 0, precache: bool = false) -> void:
	#super(amnt, precache)
	if val == null: val = Highscore.judge_diff
	val = wrapi(val + amnt, 0, choice_names.size())
	Highscore.judge_diff = val

	if not precache:
		var infos: String = "\n"
		for i: int in Highscore.judgements.size():
			infos += "%s: %sms" % [
				Highscore.judgements[i].name.to_upper(),
				Highscore.TIMING_PRESETS[val][i],
			]
			if i != Highscore.TIMING_PRESETS.size()-1:
				infos += " | "
		$"../../../../".update_desc(infos)
		OptionsBar.will_restart_gameplay = true

	val_name = str(choice_names[val])
	reload_value_name()
	if not precache:
		update_every_timing()

func update_every_timing() -> void:
	var root: Control = $"../../../../"
	if not root.is_node_ready():
		return

	for option: OptionsBar in root.category_options:
		if option.name.ends_with("_timing"):
			option.set_timing(Highscore.TIMING_PRESETS[val][option.judgement_index])
