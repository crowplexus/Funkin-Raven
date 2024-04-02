## Chart parser for the codename engine chart format[br]
## differs a lot from the vanilla one, and is the reason why
## the parser system was made in the first place.
class_name CodenameParser extends ChartParser

func parse() -> Chart:
	var chart: Chart = Chart.new()
	var cne_meta: Dictionary = {}
	
	# TODO: support more of the CNE metadata #
	# maybe, idk. @crowplexus

	var meta_file: String = Chart.get_chart_path(data["folder"]) + "_meta.json"
	print(meta_file)
	if ResourceLoader.exists(meta_file):
		var file_content: String = FileAccess.open(meta_file, FileAccess.READ).get_as_text()
		cne_meta = JSON.parse_string( file_content )
	print(cne_meta)
	if "bpm" in cne_meta: chart.initial_bpm = cne_meta["bpm"]
	if "scrollSpeed" in data: chart.initial_speed = data["scrollSpeed"]

	if "strumLines" in data:

		for i in data.strumLines.size():
			var cne_sl = data.strumLines[i]

			# will only make the notes work with this for now
			if not "notes" in cne_sl: continue

			for note in cne_sl.notes:
				if ( int(note.id) < 0): continue

				var new_note: NoteData = NoteData.new()
				new_note.time = float(note.time) * 0.001
				new_note.dir = int(note.id) % NoteData.Direction.keys().size()
				new_note.s_len = maxf(float(note.sLen) * 0.001, 0)
				match i:
					0: new_note.lane = 1
					1: new_note.lane = 0
					_: new_note.lane = i
				
				for j: NoteData in chart.notes:
					if j == null: chart.notes.erase(j)
					else:
						if j.lane == new_note.lane and j.dir == new_note.dir and absf(j.time - new_note.time) < 0.001:
							new_note.unreference()
							continue
				
				chart.notes.append(new_note)
	
	if "events" in data:
		for cne_event in data.events:
			var new_event: EventData = EventData.new()
			new_event.args = cne_event.params
			new_event.time = cne_event.time

			match cne_event.name:
				"Camera Movement": new_event.name = "Camera Pan"
				_: new_event.name = cne_event.name
			
			chart.events.append(new_event)
	
	if chart.notes.size() > 1:
		chart.notes.sort_custom(func(a: NoteData, b: NoteData):
			return a.time < b.time)
	
	if chart.events.size() > 1:
		chart.events.sort_custom(func(a: EventData, b: EventData):
			return a.time < b.time)
	
	return chart
