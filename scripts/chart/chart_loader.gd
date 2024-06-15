extends Resource
class_name Chart

static var global: Chart


@export var notes: Array[Note] = []
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

	match chart_version:
		"vanilla":
			# new format, load metadata too.
			var meta_path: String = path_chosen.replace("-chart", "-metadata")
			if ResourceLoader.exists(meta_path):
				chart.convert_vanilla_metadata(JSON.parse_string(
					FileAccess.open(meta_path, FileAccess.READ)
					.get_as_text()))

			if "scrollSpeed" in jsonf:
				chart.note_speed = float(jsonf["scrollSpeed"][real_difficulty])

			# load notes
			for note: Dictionary in jsonf["notes"][real_difficulty]:
				var swag_note: Note = Chart.make_note(note)
				if "d" in note:
					var player: int = 0
					if int(note["d"]) % (chart.key_amount * 2) >= chart.key_amount:
						player = 1
					swag_note.player = player
					swag_note.speed = chart.note_speed
				chart.notes.append(swag_note)

		"legacy":
			if not "song" in jsonf:
				return chart

			if "speed" in jsonf.song:
				chart.note_speed = jsonf.song.speed
			if "bpm" in jsonf.song:
				chart.time_changes.append(Conductor.TIME_CHANGE_TEMPLATE.duplicate())
				chart.time_changes.front().bpm = jsonf.song.bpm

			# load notes from the old format
			if "notes" in jsonf.song:
				for bar: Dictionary in jsonf.song.notes:
					# important values should always exist in data
					if not "sectionNotes" in bar: bar["sectionNotes"] = []
					if not "mustHitSection" in bar: bar["mustHitSection"] = false

					for note: Array in bar["sectionNotes"]:
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
						chart.notes.append(swag_note)

	# set the bpm to the chart's bpm

	Conductor.sort_time_changes(chart.time_changes)

	#print_debug(chart)
	Conductor.time_changes = chart.time_changes
	Conductor.apply_time_change(chart.time_changes.front())

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
