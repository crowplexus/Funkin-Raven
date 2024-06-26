extends RefCounted

signal finished()

var path: String = ""
var data: String = "" # sm data is a string lol
var diff: String = SongItem.DEFAULT_DIFFICULTY_SET[1].file


func parse_sm() -> Chart:
	var chart: Chart = Chart.new()

	var map_dat: PackedStringArray = data.split(";")
	for line: String in map_dat:
		line = line.dedent().strip_edges()
		if not "#" in line:
			continue

		var key: PackedStringArray = line.split(":")
		match key[0]:
			"#TITLE": chart.song_info.name = key[1]
			"#ARTIST": chart.song_info.credits.composer = key[1]
			"#NOTES":
				#var v: String = key[0]+":"+key[1]+":"+key[2]+":"+key[3]
				#value = key[4]+":"+key[5]+":"+key[6]
				#print_debug(key[1])
				pass
			_: # let's pretend we don't know
				var _value: String = ":".join(line.split(":"))

	finished.emit()
	return chart
