extends Resource
class_name Chart

const PARSERS: Dictionary = {
	"funkin": preload("res://scripts/chart/formats/funkin.gd"),
	"stepmania": preload("res://scripts/chart/formats/stepmania.gd"),
}

static var global: Chart

@export var notes: Array[Note] = []
@export var events: Array[ChartEvent] = []
@export var time_changes: Array[Dictionary] = []
@export var song_info: SongInfo = SongInfo.new()
@export var note_speed: float = 1.0


func _to_string() -> String:
	var chart_string: String = ""
	chart_string += "Note Count: %s" % self.notes.size()
	chart_string += "\nSong Info: { %s }" % self.song_info
	return chart_string

static func load_default() -> Chart:
	return Chart.request("test", SongItem.DEFAULT_DIFFICULTY_SET.hard)

static func request(song: StringName, difficulty: Dictionary = { "file": "normal", "target": "normal", "variation": "" }) -> Chart:
	var path_chosen: String = ""
	# set the *real* chart difficulty
	var real_difficulty: StringName = difficulty.file
	if "target" in difficulty:
		real_difficulty = difficulty.target
	elif not difficulty.variation.is_empty():
		real_difficulty = difficulty.variation

	var file_paths: PackedStringArray = [
		# FNF naming schemes
		"res://assets/songs/%s/%s-chart-%s.json" % [song, song, difficulty.file],
		"res://assets/songs/%s/%s-%s.json" % [song, song, difficulty.file],
		"res://assets/songs/%s/%s-chart.json" % [song, song],
		"res://assets/songs/%s/%s.json" % [song, difficulty.file],
		"res://assets/songs/%s/%s.json" % [song, real_difficulty],
		"res://assets/songs/%s/%s.json" % [song, song],
		# stepmania naming schemes
		"res://assets/songs/%s/%s.sm" % [song, song],
	]

	for i: String in file_paths:
		if ResourceLoader.exists(i):
			path_chosen = i
			break

	# now that we found the chart file, load the chart
	# and also reset the conductor
	Conductor.reset()

	if path_chosen.is_empty():
		push_warning("Unable to load song at folder: ", song, ", with difficulty: ", difficulty, ", please check your files.")
		return Chart.new()

	# always assuming legacy/psych engine format
	var chart_version: StringName = "legacy"
	if path_chosen.get_extension() == "sm":
		chart_version = "sm"

	var chart: Chart = Chart.new()

	match chart_version:
		"vanilla", "base", "legacy", "psych":
			var jsonf: Dictionary = JSON.parse_string(
				FileAccess.open(path_chosen, FileAccess.READ)
				.get_as_text())

			if "notes" in jsonf: chart_version = "vanilla"
			elif "song" in jsonf: chart_version = "legacy"

			var parser: = PARSERS["funkin"].new()
			parser.path = path_chosen
			parser.diff = real_difficulty
			parser.data = jsonf
			if chart_version == "legacy" or chart_version == "psych":
				chart = parser.parse_legacy(song, difficulty)
			else:
				chart = parser.parse_base(song, difficulty)
			parser.unreference()
		"sm":
			var parser: = PARSERS["stepmania"].new()
			parser.path = path_chosen
			parser.diff = real_difficulty
			parser.data = FileAccess.open(path_chosen, FileAccess.READ).get_as_text()
			chart = parser.parse_sm()
			parser.unreference()

	chart.notes.sort_custom(func(a: Note, b: Note):
		return a.time < b.time)
	chart.events.sort_custom(func(a: ChartEvent, b: ChartEvent):
		return a.step < b.step)

	# set the bpm to the chart's bpm
	if not chart.time_changes.is_empty():
		Conductor.sort_time_changes(chart.time_changes)
		Conductor.time_changes = chart.time_changes
		Conductor.apply_time_change(chart.time_changes.front())
	#print_debug(chart)

	return chart
