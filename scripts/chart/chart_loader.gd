extends Resource
class_name Chart

static var global: Chart



@export var notes: Array[Note] = []
@export var events: Array[ChartEvent] = []
@export var time_changes: Array[Dictionary] = []
@export var song_info: SongInfo = SongInfo.new()
@export var key_amount: int = 4
@export var note_speed: float = 1.0


func _to_string() -> String:
	var chart_string: String = ""
	chart_string += "Note Count: %s" % self.notes.size()
	chart_string += "\nSong Info: { %s }" % self.song_info
	return chart_string


static func request(song: StringName, difficulty: Dictionary = { "file": "normal", "target": "normal", "variation": "" }) -> Chart:
	var chart: Chart = Chart.new()
	var path_chosen: String = ""
	chart.song_info.folder = song
	chart.song_info.difficulty = difficulty

	# set the *real* chart difficulty
	var real_difficulty: StringName = difficulty.file
	if "target" in difficulty:
		real_difficulty = difficulty.target
	elif not difficulty.variation.is_empty():
		real_difficulty = difficulty.variation

	var file_names: PackedStringArray = [
		difficulty.file,
		real_difficulty,
		"%s-%s" % [song, difficulty.file],
		"%s-chart-%s" % [song, difficulty.file],
		"%s-chart" % song,
		song, # worst case scenario
	]

	for i: String in file_names:
		var path: String = "res://assets/songs/%s/%s.json" % [song, i]
		if ResourceLoader.exists(path):
			path_chosen = path
			break

	if path_chosen.is_empty():
		push_warning("Unable to load song at folder: ", song, ", with difficulty: ", difficulty, ", please check your files.")
		return chart

	# now that we found the chart file, load the chart
	# and also reset the conductor
	Conductor.reset()

	# always assuming legacy/psych engien format
	var chart_version: StringName = "legacy"

	var jsonf: Dictionary = JSON.parse_string(
		FileAccess.open(path_chosen, FileAccess.READ)
		.get_as_text())

	if "notes" in jsonf and real_difficulty in jsonf["notes"]:
		chart_version = "vanilla"

	if "strumConfig" in jsonf and jsonf["strumConfig"] is Array:
		chart.song_info.notefields.clear()
		for i: int in jsonf["strumConfig"].size():
			var cfg: Dictionary = jsonf["strumConfig"][i]
			var nfg: Dictionary = SongInfo.parse_json_notefield_conf(cfg, i)
			chart.song_info.notefields.append(nfg)

	var fake_bpm: float = 0.0
	var fake_crotchet: float = 0.0
	var time_change_id: int = 0
	var steps_per_beat: int = 4
	var beats_per_bar: int = 4

	match chart_version:
		"vanilla", "base":
			# new format, load metadata too.
			var meta_path: String = path_chosen.replace("-chart", "-metadata")
			if ResourceLoader.exists(meta_path):
				chart.convert_vanilla_metadata(JSON.parse_string(
					FileAccess.open(meta_path, FileAccess.READ)
					.get_as_text()))

			if fake_bpm != chart.time_changes[time_change_id].bpm:
				fake_bpm = chart.time_changes[time_change_id].bpm
				steps_per_beat = chart.time_changes[time_change_id].signature_num
				beats_per_bar = chart.time_changes[time_change_id].signature_den
				fake_crotchet = (60.0 / fake_bpm)

			if "scrollSpeed" in jsonf and real_difficulty in jsonf["scrollSpeed"]:
				chart.note_speed = float(jsonf["scrollSpeed"][real_difficulty])

			# load notes
			for note: Dictionary in jsonf["notes"][real_difficulty]:
				if "d" in note and int(note["d"]) == -1:
					continue

				var swag_note: Note = Chart.make_note(note)
				var player: int = 0
				if int(note["d"]) % (chart.key_amount * 2) >= chart.key_amount:
					player = 1
				swag_note.player = player
				swag_note.speed = chart.note_speed
				swag_note.visual_time = swag_note.time
				chart.notes.append(swag_note)

			if "events" in jsonf:
				for event: Dictionary in jsonf.events:
					chart.events.append(Chart.convert_vanilla_event(event, fake_bpm))
			time_change_id = clampi(time_change_id + 1, 0, chart.time_changes.size())

		"legacy", "psych":
			if not "song" in jsonf:
				return chart

			var bar_timer: float = 0.0

			if "speed" in jsonf.song:
				chart.note_speed = jsonf.song.speed
			if "bpm" in jsonf.song:
				chart.time_changes.append(Conductor.TIME_CHANGE_TEMPLATE.duplicate())
				chart.time_changes[time_change_id].bpm = jsonf.song.bpm
			if "player1" in jsonf.song:
				chart.song_info.characters.append(jsonf.song.player1)
			if "player2" in jsonf.song:
				chart.song_info.characters.append(jsonf.song.player2)
			if "gfVersion" in jsonf.song:
				chart.song_info.characters.append(jsonf.song["gfVersion"])
			if "stage" in jsonf.song:
				chart.song_info.background = jsonf.song.stage

			if fake_bpm != chart.time_changes[time_change_id].bpm:
				fake_bpm = chart.time_changes[time_change_id].bpm
				steps_per_beat = chart.time_changes[time_change_id].signature_num
				beats_per_bar = chart.time_changes[time_change_id].signature_den
				fake_crotchet = (60.0 / fake_bpm)

			# load notes from the old format
			if "notes" in jsonf.song:
				for bar: Dictionary in jsonf.song.notes:
					# important values should always exist in data
					if not "sectionNotes" in bar: bar["sectionNotes"] = []
					if not "mustHitSection" in bar: bar["mustHitSection"] = false
					if not "changeBPM" in bar: bar["changeBPM"] = false
					if not "bpm" in bar: bar["bpm"] = fake_bpm

					for note: Array in bar["sectionNotes"]:
						if int(note[1]) == -1:
							# classic psych engine events / lullaby events
							var classic_event: ChartEvent = ChartEvent.new()
							classic_event.name = note[2]
							classic_event.values = { "v1": note[3], "v2": note[4] }
							classic_event.step = Conductor.time_to_step(note[0] * 0.001)
							chart.events.append(classic_event)
							continue
						if note[1] is Array:
							for e: int in note[1].size():
								chart.events.append(make_psych_event(
									[note[0], note[1]], e)
								)
							continue

						var note_kind: StringName = "normal"
						if 3 in note and note[3] is String:
							note_kind = StringName(note[3])

						var swag_note: Note = Chart.make_note({
							"t": float(note[0]), # Time
							"d": int(note[1]), # Column
							"l": float(note[2]), # Sustain Length
							"k": note_kind, # Kind
						}, chart.key_amount)

						# 0 -> Player, 1 -> Enemy
						var player: int = int(not bar["mustHitSection"])
						if int(note[1]) % (chart.key_amount * 2) >= chart.key_amount:
							player = int(bar["mustHitSection"])
						swag_note.player = player
						swag_note.speed = chart.note_speed
						swag_note.visual_time = swag_note.time
						chart.notes.append(swag_note)

					var focus_camera: ChartEvent = ChartEvent.new()
					focus_camera.step = Conductor.time_to_step(bar_timer)
					focus_camera.values = {
						"char": int(not bar["mustHitSection"]) + 1,
						"ease": "CLASSIC",
					}
					focus_camera.name = "FocusCamera"
					chart.events.append(focus_camera)

					if bar["changeBPM"] == true and fake_bpm != bar.bpm:
						var bpm_change: = Conductor.TIME_CHANGE_TEMPLATE.duplicate()
						bpm_change.beat_time = bar_timer
						bpm_change.bpm = bar.bpm
						chart.time_changes.append(bpm_change)

					time_change_id = clampi(time_change_id + 1, 0, chart.time_changes.size())
					bar_timer += fake_crotchet * beats_per_bar

	chart.notes.sort_custom(func(a: Note, b: Note):
		return a.time < b.time)
	chart.events.sort_custom(func(a: ChartEvent, b: ChartEvent):
		return a.step < b.step)

	# set the bpm to the chart's bpm
	Conductor.sort_time_changes(chart.time_changes)
	Conductor.time_changes = chart.time_changes
	Conductor.apply_time_change(chart.time_changes.front())
	#print_debug(chart)

	return chart


func convert_vanilla_metadata(_meta: Dictionary) -> void:
	# convert base game time changes
	if "timeChanges" in _meta:
		for i: Dictionary in _meta["timeChanges"]:
			time_changes.append(Conductor.time_change_from_vanilla(i))
	# convert some of its play data
	if "songName" in _meta:
		song_info.name = _meta["songName"]
	if "playData" in _meta:
		if "characters" in _meta["playData"]:
			var chars: Dictionary = _meta["playData"].characters
			song_info.characters = [chars.player, chars.opponent, chars.girlfriend]
			if song_info.characters.has("album"):
				song_info.characters.remove_at(song_info.characters.find("album"))
		#if "difficulties" in _meta["playData"]:
		#	song_info.difficulties = []
		#	for diff: String in _meta["playData"].difficulties:
		#		song_info.difficulties.append(StringName(diff))
		if "stage" in _meta["playData"]:
			song_info.background = _meta["playData"].stage
		if "ratings" in _meta["playData"]:
			song_info.stars = _meta["playData"].ratings


static func make_note(data: Dictionary, _key_amount: int = 4) -> Note:
	var swag_note: Note = Note.new()
	if "t" in data: swag_note.time = float(data["t"] * 0.001)
	if "d" in data: swag_note.column = int(data["d"]) % _key_amount
	if "l" in data: swag_note.hold_length = float(data["l"] * 0.001)
	if "k" in data:
		match data["k"]:
			"Hurt Note": swag_note.kind = "mine"
			_: swag_note.kind = StringName(data["k"])
	return swag_note


static func convert_vanilla_event(event: Dictionary, bpm: float) -> ChartEvent:
	# convert base game events
	var e: ChartEvent = ChartEvent.new()
	e.name = str(event.e)
	e.step = Conductor.time_to_step(event.t * 0.001, bpm)
	match event.e:
		"FocusCamera":
			match event.v:
				_:
					if event.v is int or event.v is float:
						e.values = { "char": event.v }
					elif event.v is Dictionary:
						e.values = event.v
					if "char" in e.values:
						var lol = e.values.char
						if lol is String: lol = lol.to_int()
						e.values.char = int(lol + 1)
					if not "ease" in e.values:
						e.values.ease = "CLASSIC"
		_:
			e.values = event.v
	return e


static func make_psych_event(event: Array, column: int) -> ChartEvent:
	var e: ChartEvent = ChartEvent.new()
	e.name = event[1][column][0]
	e.values = {
		"v1": event[1][column][1],
		"v2": event[1][column][2],
	}
	e.step = Conductor.time_to_step(event[0] * 0.001)
	return e
