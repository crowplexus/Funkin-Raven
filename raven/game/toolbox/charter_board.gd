## Handles The Charter Notes.
extends ColorRect

@onready var info_label: = $"../text/conductor"
@onready var lanes: = $lanes

var selected_notes:Array[Note] = []

var cur_note:int = 0
var note_list:Array[NoteData]
var note_spacing:float = 160.0:
	set(new_spacing):
		note_spacing = clampf(new_spacing, 80.0, 640.0)
		zoom = 160.0 / note_spacing
		material.set_shader_parameter("spacing", note_spacing)
		spawn_notes(true) # spawn backwards than forward. weird but it should work.
		spawn_notes(false)
		for lane:NoteField in lanes.get_children():
			for note:Note in lane.note_group.get_children():
				note.clip_rect.size.y = (note_spacing * (note.data.s_len / Conductor.beatc)) / note.global_scale.y
		update()
var zoom:float = 1.0

## The current snap index to use.
var cur_snap:int = 3:
	set(new_snap):
		cur_snap = clampi(new_snap, 0, snap_list.size() - 1)
		snap_inc = Conductor.barc * snap_list[cur_snap]["mult"]
		color = snap_list[cur_snap]["color"]
		update()
## Contains data for snapping.
var snap_list = [
	{"display": 4, "mult": 1.0 / 4.0, "color": Color8(255, 56, 112, 192) * 0.75},
	{"display": 8, "mult": 1.0 / 8.0, "color": Color8(70, 103, 128, 192)},
	{"display": 12, "mult": 1.0 / 12.0, "color": Color8(192, 66, 255, 192) * 0.75},
	{"display": 16, "mult": 1.0 / 16.0, "color": Color8(0, 255, 123, 192) * 0.75},
	{"display": 20, "mult": 1.0 / 20.0, "color": Color8(196, 196, 196, 192) * 0.75},
	{"display": 24, "mult": 1.0 / 24.0, "color": Color8(255, 150, 234, 192) * 0.85},
	{"display": 32, "mult": 1.0 / 32.0, "color": Color8(255, 255, 82, 192) * 0.75},
	{"display": 48, "mult": 1.0 / 48.0, "color": Color8(170, 0, 255, 192) * 0.75},
	{"display": 64, "mult": 1.0 / 64.0, "color": Color8(0, 255, 255, 120)},
	{"display": 192, "mult": 1.0 / 192.0, "color": Color8(196, 196, 196, 192) * 0.75}
]
var snap_inc:float = 1.0

## Contains Notes and Notetypes.
const NOTE_TYPES: Array[Resource] = [
	preload("res://raven/game/notes/default.tscn")
]

func on_ready():
	for lane:NoteField in lanes.get_children():
		for strum:Receptor in lane.receptors.get_children():
			strum.animplayer.animation_finished.connect(func(anim_name):
				if anim_name == "confirm":
					strum.play_anim("static")
			)
	
	note_list = PlayField.chart.notes.duplicate()
	snap_inc = Conductor.barc * snap_list[cur_snap]["mult"]
	color = snap_list[cur_snap]["color"]
	
	spawn_notes()
	update()
	
func spawn_notes(backward:bool = false):
	if note_list.size() <= 0: return
	
	var forward_range = Conductor.beatc * 4 * zoom + 0.001
	if backward:
		cur_note -= int(cur_note == note_list.size())
		for lane:NoteField in lanes.get_children():
			for note:Note in lane.note_group.get_children():
				if note.data.time - Conductor.time < forward_range: continue
				if selected_notes.has(note):
					selected_notes.erase(note)
				note.queue_free()
		while cur_note >= 0 and cur_note < note_list.size() and note_list[cur_note].time - Conductor.time >= -Conductor.beatc * zoom:
			var unspawn:NoteData = note_list[cur_note]
			var lane: NoteField = lanes.get_child(unspawn.lane % lanes.get_child_count())
			add_note(unspawn, lane)
			cur_note -= 1
		cur_note += int(cur_note < 0)
	else:
		while cur_note < note_list.size() and note_list[cur_note].time - Conductor.time < forward_range:
			var unspawn:NoteData = note_list[cur_note]
			var lane: NoteField = lanes.get_child(unspawn.lane % lanes.get_child_count())
			add_note(unspawn, lane)
			cur_note += 1

func update():
	material.set_shader_parameter("offset", note_spacing * (1.0 - fmod(Conductor.beatf, 1.0)))
	material.set_shader_parameter("curLine", int(fmod(Conductor.beatf, 4.0)))
	var delete_window:float = Conductor.beatc * zoom
	for lane:NoteField in lanes.get_children():
		for note:Note in lane.note_group.get_children():
			note.global_position = Vector2(note.receptor.global_position.x, note.receptor.global_position.y + note_spacing * (Conductor.time_to_beat(note.data.time) - Conductor.beatf))
			var old_mod = note.modulate.a
			note.modulate.a = 1.0;
			if (note.data.time + note.data.s_len) - Conductor.time < -delete_window:
				if selected_notes.has(note):
					selected_notes.erase(note)
				note.queue_free()
			elif note.data.time < Conductor.time:
				if Conductor.active and old_mod == 1.0:
					note.receptor.play_anim("confirm", true)
				note.modulate.a = 0.6;
	
	info_label.text = "BPM:%d | Time: %02d:%02d\n Snap:%s | Zoom:%sx\n Step:%d | Beat:%d\nBar:%d" % [
		Conductor.bpm,
		floori(Conductor.time / 60.0),
		floori(fmod(Conductor.time, 60)),
		snap_list[cur_snap]["display"],
		zoom,
		Conductor.stepf,
		Conductor.beatf,
		Conductor.barf
	]
	
func try_add(index:int):
	var dirs: = NoteData.Direction.keys()
			
	var new_note: NoteData = try_delete(index % dirs.size(), 1 - floori(index / dirs.size()))
	if new_note == null: return
	
	var _cur_note:int = cur_note
	var insert_index:int = cur_note
	while insert_index > 0 and insert_index < note_list.size() and note_list[insert_index].time > Conductor.time:
		insert_index -= 1
	if insert_index < note_list.size():
		insert_index += int(note_list[insert_index].time < Conductor.time)
	note_list.insert(insert_index, new_note)

	for _lane:NoteField in lanes.get_children():
		var notes = _lane.note_group.get_children()
		notes.reverse()
		for _note:Note in notes:
			_note.name = "Note" + str(note_list.find(_note.data)) + "_0"

	var lane: NoteField = lanes.get_child(new_note.lane)
	cur_note = insert_index
	for note in selected_notes: note.selected = false
	selected_notes = [add_note(new_note, lane)]
	selected_notes[0].selected = true
	cur_note = _cur_note
	
func try_delete(dir:int, lane:int):
	var time = floorf((Conductor.time + 0.001) / snap_inc) * snap_inc # add an extra milisecond cuz flooring can be wacky sometimes.
	time = roundf(time * 10000) * 0.0001 # add a little rounding as some notes may not get deleted.
	var removed:bool = false
	for note:Note in lanes.get_child(lane).note_group.get_children():
		if roundf(note.data.time * 10000) * 0.0001 == time and note.data.dir == dir:
			removed = true
			note_list.erase(note.data)
			if selected_notes.has(note):
				selected_notes.erase(note)
			note.queue_free()
	if removed: return null
	
	var new_note: NoteData = NoteData.new()
	new_note.time = time
	new_note.dir = dir
	new_note.lane = lane
	return new_note
	
func add_note(unspawn:NoteData, lane:NoteField):
	var note_name: = "Note" + str(cur_note) + "_0" # originally for debugging but can also fix duping
	if lane.note_group.has_node(note_name): return null
	var type: int = unspawn.type
	if NOTE_TYPES[type] == null:
		type = 0
	
	var note: Note = NOTE_TYPES[type].instantiate() as Note
	note.receptor = lane.receptors.get_child(unspawn.dir) as Receptor

	note.data = unspawn; note.debug = true
	lane.note_group.add_child(note)
	note.name = note_name
	note.clip_rect.size.y = (note_spacing * (note.data.s_len / Conductor.beatc)) / note.global_scale.y
	return note
