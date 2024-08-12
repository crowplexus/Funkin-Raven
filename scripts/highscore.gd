extends Resource
class_name Highscore

static var cached_hi: Highscore

@export var data: Dictionary = {}
@export var last_modified: String = "UNKOWN-DATE UNKNOWN-TIME"

static func check_signature(hi: Highscore, hi2: Highscore = null) -> bool:
	if not is_instance_valid(hi2): hi2 = Highscore.open()
	return is_same(hi, hi2)

static func open() -> Highscore:
	var path: String = "user://highscores.tres"
	if not ResourceLoader.exists(path):
		ResourceSaver.save(Highscore.new(), path, ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES)
	return ResourceLoader.load(path)

static func save(hi: Highscore) -> void:
	if not check_signature(hi):
		hi = Highscore.open()
	ResourceSaver.save(hi)

static func get_hi(hi: Highscore, song: String, difficulty: Dictionary = {}) -> Tally:
	if not check_signature(hi):
		hi = Highscore.open()
	var real_difficulty: StringName = difficulty.file
	if "target" in difficulty:
		real_difficulty = difficulty.target
	elif not difficulty.variation.is_empty():
		real_difficulty = difficulty.variation
	var save_name: String = song+"_"+real_difficulty
	if hi and hi.data and save_name in hi.data and hi.data[save_name] is Array:
		return hi.data[save_name][0]
	return null

static func register(tally: Tally, song: String, difficulty: Dictionary = {}) -> void:
	if difficulty.is_empty():
		difficulty = {
			"display_name": "Unknown",
			"file": "unknown",
			"variation": "",
		}
	# set the *real* difficulty
	var real_difficulty: StringName = difficulty.file
	if "target" in difficulty:
		real_difficulty = difficulty.target
	elif not difficulty.variation.is_empty():
		real_difficulty = difficulty.variation

	if not check_signature(cached_hi):
		cached_hi = Highscore.open()
	var save_name: String = song+"_"+real_difficulty
	if not save_name in cached_hi.data: cached_hi.data[save_name] = []
	cached_hi.data[save_name].append(tally.register())
	cached_hi.last_modified = Time.get_datetime_string_from_system(false, true)
	Highscore.save(cached_hi)
	print_debug("Registered song score for, ", song, " [", difficulty.display_name, "]")
