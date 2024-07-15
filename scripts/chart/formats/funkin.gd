extends RefCounted

signal finished()

var path: String = ""
var data: Dictionary = {}
var diff: String = SongItem.DEFAULT_DIFFICULTY_SET.normal.file

#region Parsers

func parse_song_metadata(song: StringName, difficulty: Dictionary = {}) -> SongInfo:
	var meta: SongInfo
	for i: String in [
		"res://assets/songs/%s/raven_meta_%s.tres" % [song, difficulty.variation],
		"res://assets/songs/%s/%s_meta_%s.tres" % [song, song, difficulty.variation],
		"res://assets/songs/%s/raven_meta.tres" % song,
		"res://assets/songs/%s/%s_meta.tres" % [song, song],
	]:
		if ResourceLoader.exists(i):
			meta = load(i) as SongInfo
			break
	if not is_instance_valid(meta):
		meta = SongInfo.new()
	return meta


func parse_base(song: StringName, difficulty: Dictionary = {}) -> Chart:
	var chart: Chart = Chart.new()

	chart.song_info = parse_song_metadata(song, difficulty)
	chart.song_info.folder = song
	chart.song_info.difficulty = difficulty

	if "strumConfig" in data and data["strumConfig"] is Array:
		chart.song_info.notefields.clear()
		for i: int in data["strumConfig"].size():
			var cfg: Dictionary = data["strumConfig"][i]
			var nfg: Dictionary = SongInfo.parse_json_notefield_conf(cfg, i)
			chart.song_info.notefields.append(nfg)

	var _fake_bpm: float = 0.0
	var _fake_crotchet: float = 0.0
	var _steps_per_beat: int = 4
	var _beats_per_bar: int = 4
	var _tcid: int = 0

	# new format, load metadata too.
	var meta_path: String = path.replace("-chart", "-metadata")
	if ResourceLoader.exists(meta_path):
		var _meta: Dictionary = JSON.parse_string(FileAccess.open(meta_path, FileAccess.READ).get_as_text())
		if "timeChanges" in _meta: # convert base game time changes
			for i: Dictionary in _meta["timeChanges"]:
				chart.time_changes.append(Conductor.time_change_from_vanilla(i))
		chart.song_info = convert_meta(chart.song_info,_meta)
		print_debug(chart.song_info)

	if _fake_bpm != chart.time_changes[_tcid].bpm:
		_fake_bpm = chart.time_changes[_tcid].bpm
		_steps_per_beat = chart.time_changes[_tcid].signature_num
		_beats_per_bar = chart.time_changes[_tcid].signature_den
		_fake_crotchet = (60.0 / _fake_bpm)

	if "scrollSpeed" in data and diff in data["scrollSpeed"]:
		chart.note_speed = float(data["scrollSpeed"][diff])

	# load notes
	for note: Dictionary in data["notes"][diff]:
		if "d" in note and int(note["d"]) == -1:
			continue

		# 0 -> Player, 1 -> Enemy
		var player: int = 0
		var nf: Dictionary = chart.song_info.notefields[player]
		if int(note["d"]) % (nf.key_count * 2) >= nf.key_count:
			player = 1
		nf = chart.song_info.notefields[player]

		var swag_note: Note = make_note(note, chart.song_info.notefields[player].key_count)
		swag_note.speed = chart.note_speed
		swag_note.player = player
		swag_note.reset()
		chart.notes.append(swag_note)

	if "events" in data:
		for event: Dictionary in data.events:
			chart.events.append(convert_event(event, _fake_bpm))
	_tcid = clampi(_tcid + 1, 0, chart.time_changes.size())

	finished.emit()
	return chart


func parse_legacy(song: StringName, difficulty: Dictionary = {}) -> Chart:
	var chart: Chart = Chart.new()

	chart.song_info = parse_song_metadata(song, difficulty)
	chart.song_info.folder = song
	chart.song_info.difficulty = difficulty

	if "strumConfig" in data and data["strumConfig"] is Array:
		chart.song_info.notefields.clear()
		for i: int in data["strumConfig"].size():
			var cfg: Dictionary = data["strumConfig"][i]
			var nfg: Dictionary = SongInfo.parse_json_notefield_conf(cfg, i)
			chart.song_info.notefields.append(nfg)

	var _bar_timer: float = 0.0

	var _fake_bpm: float = 0.0
	var _fake_crotchet: float = 0.0
	var _steps_per_beat: int = 4
	var _beats_per_bar: int = 4
	var _tcid: int = 0

	if "speed" in data.song:
		chart.note_speed = data.song.speed
	if "bpm" in data.song:
		chart.time_changes.append(Conductor.TIME_CHANGE_TEMPLATE.duplicate())
		chart.time_changes[_tcid].bpm = data.song.bpm
	if "player1" in data.song:
		chart.song_info.characters.append(data.song.player1)
	if "player2" in data.song:
		chart.song_info.characters.append(data.song.player2)
	if "gfVersion" in data.song:
		chart.song_info.characters.append(data.song["gfVersion"])
	if "stage" in data.song:
		chart.song_info.background = data.song.stage

	if _fake_bpm != chart.time_changes[_tcid].bpm:
		_fake_bpm = chart.time_changes[_tcid].bpm
		_steps_per_beat = chart.time_changes[_tcid].signature_num
		_beats_per_bar = chart.time_changes[_tcid].signature_den
		_fake_crotchet = (60.0 / _fake_bpm)

	# load notes from the old format
	if "notes" in data.song:
		for bar: Dictionary in data.song.notes:
			# important values should always exist in data
			if not "sectionNotes" in bar: bar["sectionNotes"] = []
			if not "mustHitSection" in bar: bar["mustHitSection"] = false
			if not "changeBPM" in bar: bar["changeBPM"] = false
			if not "bpm" in bar: bar["bpm"] = _fake_bpm

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
						chart.events.append(make_psych_event( [note[0], note[1]], e) )
					continue

				var note_kind: StringName = "normal"
				if 3 in note and note[3] is String:
					note_kind = StringName(note[3])

				# 0 -> Player, 1 -> Enemy
				var player: int = int(not bar["mustHitSection"])
				var nf: Dictionary = chart.song_info.notefields[player]
				if int(note[1]) % (nf.key_count * 2) >= nf.key_count:
					player = int(bar["mustHitSection"])
					nf = chart.song_info.notefields[player]

				var swag_note: Note = make_note({
					"t": float(note[0]), # Time
					"d": int(note[1]), # Column
					"l": float(note[2]), # Sustain Length
					"k": note_kind, # Kind
				}, nf.key_count)
				swag_note.speed = chart.note_speed
				swag_note.player = player
				swag_note.reset()
				chart.notes.append(swag_note)

			var focus_camera: ChartEvent = ChartEvent.new()
			focus_camera.step = Conductor.time_to_step(_bar_timer)
			focus_camera.values = {
				"char": int(not bar["mustHitSection"]) + 1,
				"ease": "CLASSIC",
				"x": 0.0, "y": 0.0,
				"duration": 4.0
			}
			focus_camera.name = "FocusCamera"
			chart.events.append(focus_camera)

			if bar["changeBPM"] == true and _fake_bpm != bar.bpm:
				var bpm_change: = Conductor.TIME_CHANGE_TEMPLATE.duplicate()
				bpm_change.beat_time = _bar_timer
				bpm_change.bpm = bar.bpm
				chart.time_changes.append(bpm_change)

			_tcid = clampi(_tcid + 1, 0, chart.time_changes.size())
			_bar_timer += _fake_crotchet * _beats_per_bar

	if not chart.song_info.instrumental:
		var fol: String = "res://assets/songs/%s/Inst.ogg" % song
		if not ResourceLoader.exists(fol):
			fol = fol.replace(song, "test")
		chart.song_info.instrumental = load(fol)
	if chart.song_info.vocals.is_empty():
		var fol: String = "res://assets/songs/%s/Voices.ogg" % song
		if not ResourceLoader.exists(fol):
			fol = fol.replace(song, "test")
		chart.song_info.vocals.append(load(fol) as AudioStream)

	finished.emit()
	return chart

#endregion
#region Utils

func convert_meta(sf: SongInfo, _meta: Dictionary) -> SongInfo:
	if "songName" in _meta and sf.name == "<REPLACE>":
		sf.name = _meta["songName"]
	if "artist" in _meta: sf.credits.artist = _meta.artist
	if "charter" in _meta: sf.credits.charter = _meta.charter
	# convert some of base game's play data
	if "playData" in _meta:
		if "characters" in _meta["playData"] and sf.characters.is_empty():
			var chars: Dictionary = _meta["playData"].characters
			sf.characters = [chars.player, chars.opponent, chars.girlfriend]
			if sf.characters.has("album"):
				sf.characters.remove_at(sf.characters.find("album"))
		#if "difficulties" in _meta["playData"]:
		#	song_info.difficulties = []
		#	for diff: String in _meta["playData"].difficulties:
		#		song_info.difficulties.append(StringName(diff))
		if "stage" in _meta["playData"] and sf.background.is_empty():
			sf.background = _meta["playData"].stage
		if "ratings" in _meta["playData"] and sf.stars.is_empty():
			sf.stars = _meta["playData"].ratings
	return sf


func make_note(note_data: Dictionary, _key_amount: int = 4) -> Note:
	var swag_note: Note = Note.new()
	if "t" in note_data: swag_note.time = float(note_data["t"] * 0.001)
	if "d" in note_data: swag_note.column = int(note_data["d"]) % _key_amount
	if "l" in note_data: swag_note.hold_length = float(note_data["l"] * 0.001)
	if "k" in note_data:
		match note_data["k"]:
			"Hurt Note": swag_note.kind = "mine"
			_: swag_note.kind = StringName(note_data["k"])
	return swag_note


func convert_event(event: Dictionary, bpm: float) -> ChartEvent:
	# convert base game events
	var e: ChartEvent = ChartEvent.new()
	e.name = str(event.e)
	e.step = Conductor.time_to_step(event.t * 0.001, bpm)
	match event.e:
		"FocusCamera":
			match event.v:
				_:
					e.values = {
						"char": -1,
						"ease": "CLASSIC",
						"x": 0.0, "y": 0.0,
						"duration": 4.0
					}
					if event.v is int or event.v is float:
						e.values.char = event.v
					elif event.v is Dictionary:
						e.values.merge(event.v, true)
		"ZoomCamera":
			e.values = {
				"zoom": 1.0,
				"duration": 4.0,
				"mode": "stage",
				"ease": "linear"
			}
			if event.v is int or event.v is float:
				e.values.zoom = event.v
			elif event.v is Dictionary:
				e.values.merge(event.v, true)

		_:
			e.values = event.v
	return e


func make_psych_event(event: Array, column: int) -> ChartEvent:
	var e: ChartEvent = ChartEvent.new()
	e.name = event[1][column][0]
	e.values = {
		"v1": event[1][column][1],
		"v2": event[1][column][2],
	}
	e.step = Conductor.time_to_step(event[0] * 0.001)
	return e

#endregion
