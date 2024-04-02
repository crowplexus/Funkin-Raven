class_name PlayManager extends Resource

static var difficulty: String = ""

@export var playlist: Array[FreeplaySong] = []
var current_week: int = -1

@export_enum("Campaign:0", "Casual:1", "Editor:2'")
var play_mode: int = 1

var points: ScoreManager
var cur_song: int = 0

var finish_callback: Callable = func(exit_code: int = -1):
	match exit_code:
		0:
			var reached_end: bool = try_next_song(1)
			if reached_end:
				if points.valid_score:
					Highscore.save_performance_stats(
						points.get_performance(),
						"Week " + str(current_week),
						difficulty
					)
				cur_song = 0
				Tools.switch_scene(load("res://raven/game/menus/story_menu.tscn"))
			
			else:
				Tools.switch_scene(load("res://raven/game/gameplay.tscn"), true)
		1:
			if points.valid_score:
				Highscore.save_performance_stats(
					points.get_performance(),
					PlayField.song_data.name,
					difficulty
				)
			reset()
			Tools.switch_scene(load("res://raven/game/menus/freeplay.tscn"))
			
		2:
			reset()
			Tools.switch_scene(load("res://raven/game/toolbox/charter.tscn"))

func _init(mode: int = 1, week: int = -1):
	points = ScoreManager.new()
	self.current_week = week
	self.play_mode = mode

func set_playlist(new_playlist: Array[FreeplaySong]):
	self.playlist = new_playlist
	return self

func end_play_session(code: int = -1):
	finish_callback.call_deferred(code)

func try_next_song(new: int = 0) -> bool:
	if playlist.is_empty(): return true
	cur_song = clampi(cur_song + new, 0, playlist.size())
	if cur_song != playlist.size(): PlayManager.set_song(playlist[cur_song], difficulty)
	return cur_song == playlist.size()

func reset():
	#PlayManager.difficulty = ""
	points.reset_all()
	cur_song = 0
	#self.unreference()

static func set_song(data: FreeplaySong, diff: String):
	##############################
	if (is_same(diff, PlayField.play_manager.difficulty) and
		is_same(data, PlayField.song_data)):
			print("not loading what it's already loaded")
			return
	
	var file: String = find_file(data.folder, diff)
	PlayField.chart = Chart.request(data.folder, file)
	PlayManager.difficulty = diff
	PlayField.song_data = data

static func find_file(folder: String, diff: String) -> String:
	var file: String
	var chartf: String = Chart.get_chart_path(folder)
	if ResourceLoader.exists(chartf + diff + ".json"):
		file = diff + ".json"
	return file
