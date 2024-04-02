## Chart parser for the old base game format (pre v-slice)
class_name VanillaParser extends ChartParser

func parse() -> Chart:
	data = data["song"]
	var chart: Chart = Chart.new()
	chart.chars.resize(3)

	if "bpm" in data: chart.initial_bpm = data["bpm"]
	if "speed" in data: chart.initial_speed = data["speed"]

	chart.stage_bg = load("res://raven/game/stages/"+StageBG.DEFAULT_STAGE+".tscn")
	
	if "stage" in data:
		var stage_scene: String = "res://raven/game/stages/"+data["stage"]+".tscn"
		if ResourceLoader.exists(stage_scene):
			chart.stage_bg = load(stage_scene)
	
	for i: int in 4:
		var v: int = i
		var dat: StringName = "player%s" % str(i+1)
		if i == 3:
			dat = "gfVersion"
			v = 2
		if dat in data:
			var actor: String = Chart._get_actor(str(data[dat]))
			if actor != null: chart.chars[v] = load(actor)
	
	var current_bpm: float = data["bpm"]
	var timer: float = 0.0
	
	if "notes" in data:
		
		for bar in data["notes"]:
			if bar == null:
				timer += (60.0 / current_bpm) * 4.0
				continue
			
			if not "mustHitSection" in bar: bar["mustHitSection"] = true
			if not "sectionNotes" in bar: bar["sectionNotes"] = []
			
			# var current_bar: int = data["notes"].find(bar)
			var camera_pan: EventData = EventData.new()
			camera_pan.args.append( (int(not bar["mustHitSection"])+1) )
			camera_pan.name = "Camera Pan"
			camera_pan.time = timer
			chart.events.append(camera_pan)
			
			if "changeBPM" in bar and bar["changeBPM"] == true and bar["bpm"] != current_bpm:
				var bpm_change: EventData = EventData.new()
				bpm_change.args.append(bar["bpm"])
				bpm_change.name = "BPM Change"
				bpm_change.time = timer
				chart.events.append(bpm_change)
			
			for note in bar["sectionNotes"]:
				if ( int(note[1]) < 0): continue
				var new_note: NoteData = NoteData.new()
				new_note.time = float(note[0]) * 0.001
				new_note.dir = int(note[1]) % NoteData.Direction.keys().size()
				new_note.s_len = maxf(float(note[2]) * 0.001, 0)
				
				if note.size() > 3 and note[3] is String: match str(note[3]):
					# convert psych notes lol.
					"Hurt Note": new_note.type = NoteData.Type.MINE
					_: new_note.type = NoteData.type_from_string(note[3])
				
				var val :int = int(not bar["mustHitSection"]) #temporary...
				if note[1] >= NoteData.Direction.keys().size(): val = int(bar["mustHitSection"])
				new_note.lane = val
				for j: NoteData in chart.notes:
					if j == null: chart.notes.erase(j)
					else:
						if j.lane == new_note.lane and j.dir == new_note.dir and absf(j.time - new_note.time) < 0.001:
							new_note.unreference()
							continue
				chart.notes.append(new_note)
			timer += (60.0 / current_bpm) * 4.0
	
	if chart.notes.size() > 1:
		chart.notes.sort_custom(func(a: NoteData, b: NoteData):
			return a.time < b.time)
	
	if chart.events.size() > 1:
		chart.events.sort_custom(func(a: EventData, b: EventData):
			return a.time < b.time)

	return chart

func convert_psych_event(_ev: Array):
	# DO IT LATER :3 @crowplexus
	pass
