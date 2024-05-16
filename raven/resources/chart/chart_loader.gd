## acts as a basic resource for raven charts.[br][br]
## use "Chart.request(folder, file)" to actually load one,
## it will be converted to the resource accordingly.
class_name Chart extends Resource

const PARSERS: Dictionary = {
	"fnf_legacy": preload("res://raven/resources/chart/parsers/fnf_legacy_parser.gd"),
	"codename": preload("res://raven/resources/chart/parsers/codename_parser.gd"),
}

class NoteData:
	enum Columns { LEFT, DOWN, UP, RIGHT }
	enum NoteColours { PURPLE, BLUE, GREEN, RED }
	enum SustainType { HOLD, ROLL }
	enum Lane { ENEMY, PLAYER, OTHER }

	var time: float = 0.0
	var column: int = Columns.LEFT
	var lane: int = Lane.ENEMY
	var s_len: float = 0.0

	var type: StringName = "normal"
	var s_type: int = SustainType.HOLD

	func _to_string() -> String:
		return "Time:%s//Column:%s//Type:%s//Lane:%s//Sustain Length:%s" % [
			time, Columns.keys()[column], type, Lane.keys()[lane],
			s_len
		]

	static func make(_time: float, _column: int = 0, _type: StringName = "normal", _lane: int = 0) -> Chart.NoteData:
		var new_note: Chart.NoteData = Chart.NoteData.new()
		new_note.time = _time
		new_note.column = _column
		new_note.type = _type
		new_note.lane = _lane
		return new_note

	static func column_to_str(d: int) -> String:
		return Chart.NoteData.Columns.keys()[d].to_lower()
	static func color_to_str(d: int) -> String:
		return Chart.NoteData.NoteColours.keys()[d].to_lower()

	func to_dictionary() -> Dictionary:
		var note_data: Dictionary = {}
		for field in get_property_list():
			note_data[field.name] = get(field.name)
		return note_data

class EventData:
	var name: StringName = "none"
	var args: Array = []
	var time: float = 0.0
	var fire_callback: Callable

	func _to_string() -> String:
		var event_str: String = "Name: %s | Arguments: %s" % [name, args]
		if time > -1.0: event_str += " | Time: %s" % time
		return "{%s}" % event_str

	func to_dictionary() -> Dictionary:
		var event_data: Dictionary = {}
		for field in get_property_list():
			event_data[field.name] = get(field.name)
		return event_data

static var current: Chart

var notes: Array[Chart.NoteData] = []
var events: Array[Chart.EventData] = []
var note_count: Array[int] = [0, 0]

var metadata: ChartMeta
var initial_bpm: float = 100.0
var initial_speed: float = 1.0
var steps_per_beat: int = 4
var beats_per_bar : int = 4

var chars: Array[PackedScene] = []
var stage_bg: PackedScene
var version: StringName

static func request(folder: String, file: String = "normal") -> Chart:
	var chart_file: String = "%s/charts/%s" % [Chart.chart_path(folder), file]
	var chart: Chart = Chart.new()

	match chart_file.get_extension():
		"json": # JSON Parser (Vanilla, Codename Engine, etc)
			var data: Dictionary = JSON.parse_string(FileAccess.open(chart_file, FileAccess.READ).get_as_text())
			# RAVEN METADATA, WILL BE USEFUL LATER #
			data["folder"] = folder
			data["file"] = file

			if "codenameChart" in data: chart = PARSERS["codename"].new(data).parse()
			else: # assume Base Game
				chart = PARSERS["fnf_legacy"].new(data).parse()

		"res", "tres": # Raven's Custom Format
			chart = load(chart_file)
			chart.version = "Raven 1"

	var meta_path: String = Chart.chart_path(folder) + "/metadata.tres"
	if ResourceLoader.exists(meta_path):
		chart.metadata = load(meta_path)
	else:
		chart.metadata = ChartMeta.new()

	if chart.metadata.audio_tracks.is_empty():
		# OLD METHOD, THIS IS FOR USER SONGS.
		for stream: AudioStream in SoundBoard.get_streams_at(Chart.chart_path(folder) + "/audio"):
			if stream == null: continue
			stream.loop = false
			chart.metadata.audio_tracks.append(stream)

	Conductor.bpm = chart.initial_bpm
	if Conductor.bpm > 500:
		print_debug("why.")
	return chart

func save(type: int) -> void:
	match type:
		0: # resource
			ResourceSaver.save(self)
		1: # fnf (0.2.7.1/0.2.8)
			var _funkin_song: Dictionary = {
				"song": "Name",
				"notes": [],
				"bpm": self.bpm,
				"needsVoices": self.metadata.audio_tracks.size() > 1,
				"speed": self.initial_speed,
				"player1": "bf",
				"player2": "dad",
				"gfVersion": "gf",
				"validScore": true
			}
			var _funkin_section: Dictionary = {
				"sectionNotes": [],
				"sectionBeats": 4,
				"lengthInSteps": 16,
				"mustHitSection": false,
				"changeBPM": false,
				"gfSection": false,
				"altAnim": false,
				"bpm": 100.0,
			}

func dispose() -> void:
	for note: Chart.NoteData in notes:
		note.unreference()
	for event: Chart.EventData in events:
		event.unreference()
	notes.clear()
	events.clear()

	for stream: AudioStream	in metadata.audio_tracks:
		stream.unreference()

	initial_bpm = 100.0
	initial_speed = 1.0

	for i: PackedScene in chars:
		if i == null: continue
		i.unreference()
	if stage_bg != null: stage_bg.unreference()

static func chart_path(folder: String) -> String:
	var cf: String = "res://assets/data/charts/%s" % folder
	if not DirAccess.dir_exists_absolute(cf):
		cf = cf.replace("res://assets/data/charts/", "user://songs/")
	return cf

static func _get_actor(actor: String) -> String:
	if actor == null: return ""
	var char_scene: String = "res://raven/play/actors/"+actor+".tscn"
	if not ResourceLoader.exists(char_scene): # Default Character
		char_scene = char_scene.replace(actor, Character.DEFAULT_CHARACTER)
	return char_scene
