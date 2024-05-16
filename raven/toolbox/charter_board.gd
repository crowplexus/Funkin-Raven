## Handles The Charter Notes.
extends ColorRect

@onready var event_board: ColorRect = $"../board2"
@onready var info_label: Label = $"../text/conductor"
@onready var lanes: Node2D = $lanes

var selected_notes:Array[Note] = []

var cur_note:int = 0
var note_list:Array[Chart.NoteData]
var note_spacing:float = 160.0:
	set(new_spacing):
		note_spacing = clampf(new_spacing, 80.0, 640.0)
		zoom = 160.0 / note_spacing
		material.set_shader_parameter("spacing", note_spacing)
		spawn_notes(true) # spawn backwards than forward. weird but it should work.
		spawn_notes(false)
		event_board.spawn_events(true)
		event_board.spawn_events(false)
		for lane:NoteField in lanes.get_children():
			for note:Note in lane.note_group.get_children():
				note.clip_rect.size.y = (note_spacing * (note.data.s_len / Conductor.crotchet)) / note.global_scale.y
		update()
		event_board.update()

var zoom:float = 1.0
## The current snap index to use.
var cur_snap:int = 3:
	set(new_snap):
		cur_snap = clampi(new_snap, 0, snap_list.size() - 1)
		snap_inc = Conductor.semibreve * snap_list[cur_snap]["mult"]
		color = snap_list[cur_snap]["color"]
		update()

## Contains data for snapping.
var snap_list: Array[Dictionary] = [
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

func on_ready() -> void:
	note_list = PlayField.chart.notes.duplicate()
	snap_inc = Conductor.semibreve * snap_list[cur_snap]["mult"]
	color = snap_list[cur_snap]["color"]
	spawn_notes()
	update()

func spawn_notes(backward:bool = false) -> void:
	if note_list.size() <= 0: return

	var forward_range: float = Conductor.crotchet * 4 * zoom + 0.001
	if backward:
		cur_note -= int(cur_note == note_list.size())
		for lane:NoteField in lanes.get_children():
			for note:Note in lane.note_group.get_children():
				if note.data.time - Conductor.time < forward_range: continue
				if selected_notes.has(note):
					selected_notes.erase(note)
				note.queue_free()
		while cur_note >= 0 and cur_note < note_list.size() and note_list[cur_note].time - Conductor.time >= -Conductor.crotchet * zoom:
			var unspawn:Chart.NoteData = note_list[cur_note]
			var lane: NoteField = lanes.get_child(unspawn.lane % lanes.get_child_count())
			add_note(unspawn, lane)
			cur_note -= 1
		cur_note += int(cur_note < 0)
	else:
		while cur_note < note_list.size() and note_list[cur_note].time - Conductor.time < forward_range:
			var unspawn:Chart.NoteData = note_list[cur_note]
			var lane: NoteField = lanes.get_child(unspawn.lane % lanes.get_child_count())
			add_note(unspawn, lane)
			cur_note += 1

func update() -> void:
	material.set_shader_parameter("offset", note_spacing * (1.0 - fmod(Conductor.beatf, 1.0)))
	material.set_shader_parameter("curLine", int(fmod(Conductor.beatf, 4.0)))
	var delete_window:float = Conductor.crotchet * zoom
	for lane:NoteField in lanes.get_children():
		for note:Note in lane.note_group.get_children():
			note.global_position = Vector2(note.receptor.global_position.x, note.receptor.global_position.y + note_spacing * (Conductor.time_to_beat(note.data.time) - Conductor.beatf))
			var old_mod: float = note.modulate.a
			note.modulate.a = 1.0;
			if (note.data.time + note.data.s_len) - Conductor.time < -delete_window:
				if selected_notes.has(note):
					selected_notes.erase(note)
				note.queue_free()
			elif note.data.time < Conductor.time:
				if Conductor.active and old_mod == 1.0:
					note.receptor.glow_up(true)
					note.receptor.reset_timer = 0.1 + note.data.s_len
				note.modulate.a = 0.6;

	info_label.text = "BPM:%d | Time: %02d:%02d\n Snap:%s | Zoom:%sx\n Step:%d | Beat:%d\nBar:%d" % [
		Conductor.bpm,
		floori(Conductor.time / 60.0),
		floori(fmod(Conductor.time, 60)),
		snap_list[cur_snap]["display"],
		zoom,
		floori(Conductor.stepf + 0.0001),
		floori(Conductor.beatf + 0.0001),
		floori(Conductor.barf + 0.0001)
	]

func try_add(index:int) -> void:
	var dirs: = Chart.NoteData.Columns.keys()
	var new_note: Chart.NoteData = try_delete(index % dirs.size(), 1 - floorf(index / dirs.size()))
	if new_note == null:
		return

	var _cur_note:int = cur_note
	var insert_index:int = cur_note
	while insert_index > 0 and insert_index < note_list.size() and note_list[insert_index].time > Conductor.time:
		insert_index -= 1
	if insert_index < note_list.size():
		insert_index += int(note_list[insert_index].time < Conductor.time)
	note_list.insert(insert_index, new_note)
	update_note_names()

	var lane: NoteField = lanes.get_child(new_note.lane)
	cur_note = insert_index
	for note in selected_notes: note.selected = false
	selected_notes = [add_note(new_note, lane)]
	selected_notes[0].selected = true
	cur_note = _cur_note

func try_delete(column:int, lane:int) -> Chart.NoteData:
	var time: float = floorf((Conductor.time + 0.001) / snap_inc) * snap_inc # add an extra milisecond cuz flooring can be wacky sometimes.
	time = roundf(time * 10000) * 0.0001 # add a little rounding as some notes may not get deleted.
	var removed:bool = false
	for note:Note in lanes.get_child(lane).note_group.get_children():
		if roundf(note.data.time * 10000) * 0.0001 == time and note.data.column == column:
			removed = true
			note_list.erase(note.data)
			if selected_notes.has(note):
				selected_notes.erase(note)
			note.queue_free()
	if removed:
		update_note_names()
		return null

	var new_note: Chart.NoteData = Chart.NoteData.new()
	new_note.time = time
	new_note.column = column
	new_note.lane = lane
	return new_note

## TODO: REPLACE THIS WITH THE NOTE SPAWNER ITSELF
func add_note(unspawn:Chart.NoteData, lane:NoteField) -> Note:
	var note_name: String = "Note" + str(cur_note) + "_0" # originally for debugging but can also fix duping
	if lane.note_group.has_node(note_name): return null
	var type: StringName = unspawn.type
	if not NoteSpawner.NOTE_TYPES.has(type) or NoteSpawner.NOTE_TYPES[type] == null:
		type = "normal"

	var note: = NoteSpawner.NOTE_TYPES[type].instantiate() as Note
	note.receptor = lane.receptors.get_child(unspawn.column) as Receptor

	note.data.debug = true
	note.data.merge(unspawn.to_dictionary())
	lane.note_group.add_child(note)
	note.name = note_name
	note.clip_rect.size.y = (note_spacing * (note.data.s_len / Conductor.crotchet)) / note.global_scale.y
	return note

func update_note_names() -> void:
	for _lane:NoteField in lanes.get_children():
		var notes: Array = _lane.note_group.get_children()
		notes.reverse()
		for _note:Note in notes:
			_note.name = "Note" + str(note_list.find(_note.data)) + "_0"
