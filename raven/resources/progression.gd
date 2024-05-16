class_name Progression extends Resource

static var difficulty: String = ""

@export var playlist: Array[FreeplaySong] = []
var current_level: int = -1

@export_enum("Campaign:0", "Casual:1", "Editor:2'")
var play_mode: int = 1

var stats: Scoring
var cur_song: int = 0

var finish_callback: Callable = func(exit_code: int = -1) -> void:
	match exit_code:
		0:
			var reached_end: bool = try_next_song(1)
			if reached_end:
				if stats.valid_score:
					Highscore.save_performance_stats(
						stats.get_performance(),
						"Level " + str(current_level),
						difficulty
					)
				cur_song = 0
				Tools.switch_scene(load("res://raven/menu/story_menu.tscn"))
			else:
				Tools.switch_scene(load("res://raven/play/gameplay.tscn"), true)
		1:
			if stats.valid_score:
				Highscore.save_performance_stats(
					stats.get_performance(),
					PlayField.song_data.name,
					difficulty
				)
			reset()
			Tools.switch_scene(load("res://raven/menu/freeplay.tscn"))

		2:
			reset()
			Tools.switch_scene(load("res://raven/toolbox/charter.tscn"))

func _init(mode: int = 1, level: int = -1) -> void:
	stats = Scoring.new()
	self.current_level = level
	self.play_mode = mode

func set_playlist(new_playlist: Array[FreeplaySong]) -> Progression:
	self.playlist = new_playlist
	return self

func end_play_session(code: int = -1) -> void:
	finish_callback.call_deferred(code)

func try_next_song(new: int = 0) -> bool:
	if playlist.is_empty(): return true
	cur_song = clampi(cur_song + new, 0, playlist.size())
	if cur_song != playlist.size(): Progression.set_song(playlist[cur_song], difficulty)
	return cur_song == playlist.size()

func reset() -> void:
	#Progression.difficulty = ""
	stats.reset_all()
	cur_song = 0
	#self.unreference()

static func set_song(data: FreeplaySong, diff: String) -> void:
	##############################
	if (is_same(PlayField.play_manager.difficulty, diff) and
		is_same(PlayField.song_data, data)):
			print_debug("not loading what it's already loaded")
			return

	var file: String = find_file(data.folder, diff)
	PlayField.chart = Chart.request(data.folder, file)
	Progression.difficulty = diff
	PlayField.song_data = data

static func find_file(folder: String, diff: String) -> String:
	var file: String
	var path: String = Chart.chart_path(folder) + "/charts/"
	if ResourceLoader.exists( "%s.json" % [path + diff] ):
		file = diff + ".json"
	return file
