## "Chart" (internaly raven_chart.gd)[br]
## acts as a basic resource for raven charts.[br][br]
## use "Chart.request(folder, file)" to actually load one,
## it will be converted to the resource accordingly.
class_name Chart extends Resource

static var current: Chart

@export var notes: Array[NoteData] = []
@export var events: Array[EventData] = []

@export var initial_bpm: float = 100.0
@export var initial_speed: float = 1.0

@export var chars: Array[PackedScene] = []
@export var stage_bg: PackedScene
@export var metadata: ChartMeta

static func request(folder: String, file: String = "normal") -> Chart:
	var chart_file: String = "%s/%s" % [Chart.get_chart_path(folder), file]
	var chart: Chart = Chart.new()
	
	match chart_file.get_extension():
		"res", "tres": # Raven's Custom Format
			chart = load(chart_file)
		"json": # JSON Parser (Vanilla, Codename Engine, etc)
			var parser: ChartParser
			var data: Dictionary = JSON.parse_string(FileAccess.open(chart_file, FileAccess.READ).get_as_text())
			# RAVEN METADATA, WILL BE USEFUL LATER #
			data["folder"] = folder
			data["file"] = file
			
			if "codenameChart" in data:
				parser = CodenameParser.new(data)
			elif "song" in data:
				parser = VanillaParser.new(data)
			else: # DUMMY PARSER.
				parser = ChartParser.new(data)
			
			chart = parser.parse()
			parser.unreference()
	
	var meta_path: String = chart_file.replace(file, "metadata.tres")
	if ResourceLoader.exists(meta_path): chart.metadata = load(meta_path) as ChartMeta
	else: chart.metadata = ChartMeta.new()
	Conductor.bpm = chart.initial_bpm
	return chart

func dispose():
	notes.clear()
	events.clear()
	initial_bpm = 100.0
	initial_speed = 1.0
	for i: PackedScene in chars:
		if i == null: continue
		i.unreference()
	if stage_bg != null: stage_bg.unreference()
	if metadata != null: metadata.unreference()

static func get_chart_path(folder: String):
	var cf: String = "res://assets/data/charts/%s/" % folder
	if not DirAccess.dir_exists_absolute(cf):
		cf = cf.replace("res://assets/data/charts/", "user://songs/")
	return cf

static func _get_actor(actor: String):
	if actor == null: return null
	var char_scene: String = "res://raven/game/actors/"+actor+".tscn"
	if not ResourceLoader.exists(char_scene): # Default Character
		char_scene = char_scene.replace(actor, Character.DEFAULT_CHARACTER)
	return char_scene
