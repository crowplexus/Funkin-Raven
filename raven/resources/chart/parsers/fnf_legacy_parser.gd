## Chart parser for the old base game format (pre v-slice)
###
var data: Dictionary = {}

func _init(new_data: Dictionary) -> void:
	self.data = new_data

func parse() -> Chart:
	print_debug("parsing vanilla FNF chart for ", data["folder"])
	var chart: Chart = Chart.new()

	var pre_weekend_update: bool = data.has("song")
	if not pre_weekend_update:
		if data.has(data.file):
			chart.version = "Funkin"
			for note: Dictionary in data[data.file]["notes"]:
				if int(note[1]) == -1: continue # I swear to god.
				var gay_note: Chart.NoteData = Chart.NoteData.new()
				# TODO: check their metadata shit.
				# TODO (also): check how they measure time
				# data["funkin_metadata"]["timeFormat"] # ms, sec, step ????
				if note.has("t"): gay_note.time = float(note["t"]) * 0.001
				if note.has("d"): gay_note.column = int(note["d"])
				if note.has("k"): gay_note.type = String(note["k"])
				if note.has("s"): gay_note.s_len = float(note["s"]) * 0.001
				# ghost note check
				for j: Chart.NoteData in chart.notes:
					if j == null: chart.notes.erase(j)
					else:
						if j.lane == gay_note.lane and j.column == gay_note.column and absf(j.time - gay_note.time) < 0.001:
							chart.note_count[gay_note.lane] -= 1
							gay_note.unreference()
							continue
				chart.note_count[gay_note.lane] += 1
				chart.notes.append(gay_note)
	else:
		chart = parse_legacy(chart)
		chart.version = "Funkin Legacy/Funkin Engine Hybrid"

	return chart

func parse_legacy(chart: Chart) -> Chart:
	if chart == null: chart = Chart.new()

	data = data["song"]
	chart.chars.resize(3)

	if "bpm" in data: chart.initial_bpm = data["bpm"]
	if "speed" in data: chart.initial_speed = data["speed"]
	if "stepsPerBeat" in data: chart.steps_per_beat = data["stepsPerBeat"]
	if "beatsPerBar" in data: chart.beats_per_bar = data["beatsPerBar"]

	var load_default_stage: bool = not "stage" in data
	if "stage" in data:
		var stage_scene: String = "res://raven/play/stages/"+data["stage"]+".tscn"
		if ResourceLoader.exists(stage_scene):
			chart.stage_bg = load(stage_scene)
		else:
			load_default_stage = true
	if load_default_stage:
		chart.stage_bg = load("res://raven/play/stages/"+StageBG.DEFAULT_STAGE+".tscn")

	if "player1" in data:
		chart.chars[0] = load( Chart._get_actor(data["player1"]) )
	if "player2" in data:
		chart.chars[1] = load( Chart._get_actor(data["player2"]) )
	if "player3" in data and data["player3"] != null:
		chart.chars[2] = load( Chart._get_actor(data["player3"]) )
	if "gfVersion" in data and data["gfVersion"] != null:
		chart.chars[2] = load( Chart._get_actor(data["gfVersion"]) )

	var current_bpm: float = chart.initial_bpm
	var _crotchet_delta: float = (60.0 / current_bpm)
	var _semiquaver_delta: float = _crotchet_delta * 0.25
	var timer: float = 0.0

	for bar: Dictionary in data["notes"]:
		if bar == null:
			timer += _crotchet_delta * chart.beats_per_bar
			continue

		if not "mustHitSection" in bar: bar["mustHitSection"] = true
		if not "sectionNotes" in bar: bar["sectionNotes"] = []

		for note: Array in bar["sectionNotes"]:
			if int(note[1]) == -1: continue
			var piss_note: = Chart.NoteData.new()
			piss_note.time = float(note[0]) * 0.001
			piss_note.column = int(note[1]) % 4
			piss_note.s_len = maxf(float(note[2]) * 0.001, 0)

			if note.size() > 3 and note[3] is String:
				match str(note[3]):
					# convert psych notes lol.
					"Hurt Note", "Damage Note", "hurt", "damage": piss_note.type = "mine"
					_: piss_note.type = note[3]

			var val: int = int(not bar["mustHitSection"])
			if note[1] >= Chart.NoteData.Columns.keys().size():
				val = int(bar["mustHitSection"])
			piss_note.lane = val

			for j: Chart.NoteData in chart.notes:
				if j == null: chart.notes.erase(j)
				else:
					if j.lane == piss_note.lane and j.column == piss_note.column and absf(j.time - piss_note.time) < 0.001:
						chart.note_count[piss_note.lane] -= 1
						piss_note.unreference()
						continue

			chart.note_count[piss_note.lane] += 1
			chart.notes.append(piss_note)

		var camera_pan: Chart.EventData = Chart.EventData.new()
		camera_pan.args.append( (int(not bar["mustHitSection"])+1) )
		camera_pan.name = "Camera Pan"
		camera_pan.time = timer
		chart.events.append(camera_pan)

		if ("changeBPM" in bar and bar["changeBPM"] == true
				and bar["bpm"] != null and bar["bpm"] != current_bpm):
			current_bpm = bar["bpm"]
			_crotchet_delta = (60.0 / current_bpm)
			_semiquaver_delta = _crotchet_delta * 0.25

			var bpm_change: Chart.EventData = Chart.EventData.new()
			bpm_change.args.append(bar["bpm"])
			bpm_change.name = "BPM Change"
			bpm_change.time = timer
			chart.events.append(bpm_change)

		timer += _crotchet_delta * chart.beats_per_bar

	chart.notes.sort_custom(func(a: Chart.NoteData, b: Chart.NoteData) -> int:
		return a.time < b.time)
	chart.events.sort_custom(func(a: Chart.EventData, b: Chart.EventData) -> int:
		return a.time < b.time)

	return chart

func convert_psych_event(_ev: Array) -> Chart.EventData:
	var psych_event: Chart.EventData = Chart.EventData.new()
	# DO IT LATER :3 @crowplexus
	return psych_event
