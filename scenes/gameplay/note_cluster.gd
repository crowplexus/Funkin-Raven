extends Node2D
class_name NoteCluster

signal note_incoming(note: Note)

const NOTE_KIND_OBJECTS: Dictionary = {
	"normal": preload("res://scenes/gameplay/notes/normal.tscn"),
}
@export var connected_fields: Array[NoteField] = []
@export var note_queue: Array[Note] = []
@export var current_note: int = 0
var alive_queue: Array[Note] = []

func _ready() -> void:
	current_note = 0
	if Chart.global and note_queue.is_empty():
		note_queue = Chart.global.notes.duplicate()
	if not note_queue.is_empty() and not Conductor.fstep_reached.is_connected(try_spawning):
		Conductor.fstep_reached.connect(try_spawning)
	for nd: Note in note_queue:
		nd.reset()

func _exit_tree() -> void:
	if Conductor.fstep_reached.is_connected(try_spawning):
		Conductor.fstep_reached.disconnect(try_spawning)

func _process(delta: float) -> void:
	#await RenderingServer.frame_post_draw
	if not alive_queue.is_empty():
		move_notes(delta)

func move_notes(_delta: float) -> void:
	for note: Note in alive_queue:
		note.move()
		if (note.time - Conductor.time) < (-.2 - note.hold_length) and note.notefield and note.notefield.player:
			note.hit_result = note.notefield.player.get_hit_result(note)
			note.notefield.player.tallies.apply_miss(note.column, note)
			if note.notefield.player.note_miss:
				note.notefield.player.note_miss.call(note.column, note)
		if not note.moving:
			alive_queue.erase(note)

func try_spawning(_fstep: float) -> void:
	if not self.is_node_ready(): return
	await RenderingServer.frame_post_draw
	self.spawn_notes.call_deferred()

func spawn_notes() -> void:
	while current_note < note_queue.size():
		var ct: float = note_queue[current_note].time
		var relative: float = absf(ct - Conductor.time)
		var spawn_delay: float = 0.9 * note_queue[current_note].real_speed
		if note_queue[current_note].real_speed < 1.0:
			spawn_delay = 0.9 / note_queue[current_note].real_speed
		if relative > spawn_delay:
			break
		spawn_note(current_note)
		current_note += 1

func spawn_note(id: int) -> void:
	if note_queue.size() < id:
		return

	var note: Note = note_queue[id] as Note
	if note.player <= connected_fields.size():
		var field: = connected_fields[note.player]
		if field:
			note.notefield = field
			var mod: Vector2 = note.notefield.scroll_mods[note.column % note.notefield.key_count]
			note.reset_scroll(mod)

	# technically the note already spawned so
	note_incoming.emit(note)
	if not is_instance_valid(note.object):
		var kind: StringName = "normal"
		if note.kind in NOTE_KIND_OBJECTS:
			kind = note.kind
		note.object = NOTE_KIND_OBJECTS[kind].instantiate()
		note.object.name = note.kind + str(get_child_count())
		note.object.position.y = INF
	# spawn object
	if note.object and note.receptor and not note.object.top_level:
		var mod: float = note.notefield.modulate.a
		note.object.modulate.a = mod
		note.object.visible = note.receptor.visible and note.notefield.visible
		note.object.scale = note.receptor.get_global_transform().get_scale()
	note.object.set("note", note)
	#if note.notefield and note.notefield.note_group:
	#	note.notefield.note_group.add_child(note.object)
	#else:
	add_child(note.object)
	alive_queue.append(note)

func connect_notefield(new_field: NoteField) -> void:
	connected_fields.append(new_field)

func disconnect_notefield(field: NoteField) -> void:
	if connected_fields.find(field) != -1:
		connected_fields.erase(field)
