extends RefCounted

signal finished()

var path: String = ""
var data: String = "" # sm data is a string lol
var diff: String = SongItem.DEFAULT_DIFFICULTY_SET.normal.file


func parse_sm() -> Chart:
	var chart: Chart = Chart.new()
	chart.song_info = SongInfo.new()
	chart.song_info.characters = ["bf", "bf", "bf"]

	var map_dat: PackedStringArray = data.split(";")
	for line: String in map_dat:
		line = line.dedent().strip_edges()
		if not "#" in line:
			continue

		var key: PackedStringArray = line.split(":")
		match key[0]:
			"#TITLE": chart.song_info.name = key[1]
			"#ARTIST": chart.song_info.credits.composer = key[1]
			"#MUSIC":
				var audiop: String = "%s/%s" % [path, key[1]]
				chart.song_info.instrumental = load(audiop)
			#"#FNFBF": chart.song_info.characters[0] = key[1]
			#"#FNFDAD": chart.song_info.characters[1] = key[1]
			#"#FNFGF": chart.song_info.characters[2] = key[1]
			"#NOTES":
				#var note: Note = Note.new()
				#note.time = 0
				#note.column = 1
				#note.hold_length = 0
				#note.kind = "normal"
				#note.player = 0
				pass
			_: # let's pretend we don't know
				var _value: String = ":".join(line.split(":"))

	finished.emit()
	return chart
