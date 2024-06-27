extends Node2D

signal note_incoming(note: Note)

const NOTE_KIND_OBJECTS: Dictionary = {
	"normal": preload("res://scenes/gameplay/notes/normal.tscn"),
}

@export var connected_fields: Array[NoteField] = []
@export var note_queue: Array[Note] = []
@export var current_note: int = 0


func _ready() -> void:
	current_note = 0
	if not note_queue.is_empty():
		Conductor.fstep_reached.connect(try_spawning)


func _exit_tree() -> void:
	if Conductor.fstep_reached.is_connected(try_spawning):
		Conductor.fstep_reached.disconnect(try_spawning)


func _process(delta: float) -> void:
	await RenderingServer.frame_post_draw
	#if not note_queue.is_empty():
	#	spawn_notes.call_deferred()
	if get_child_count() != 0:
		move_note_objects(delta)


func move_note_objects(_delta: float) -> void:
	for note: Note in note_queue:
		if not is_instance_valid(note) or note.finished:
			continue

		var rel_time: float = note.visual_time - Conductor.time
		var note_scale: float = 0.7

		if is_instance_valid(note.object) and note.moving:
			var real_position: Vector2 = Vector2.ZERO
			if is_instance_valid(note.notefield):
				real_position = note.receptor.global_position

			note.object.global_position = note.initial_pos + real_position
			note.object.position.x *= note.scroll.x
			#note.object.position.x = note.initial_position.x + (90 * note.object.scale.x) * note.column
			note.object.position.y += rel_time * (400.0 * absf(note.real_speed)) / absf(note_scale) * note.scroll.y
			#note.object.position *= note.scroll


func try_spawning(_fstep: float) -> void:
	if not self.is_node_ready(): return
	await RenderingServer.frame_post_draw
	self.spawn_notes.call_deferred()


func spawn_notes() -> void:
	while current_note < note_queue.size():
		var ct: float = note_queue[current_note].time
		var relative: float = absf(ct - Conductor.time + (Preferences.beat_offset * 0.001))
		var spawn_delay: float = 0.9 * note_queue[current_note].real_speed
		if note_queue[current_note].real_speed < 1.0:
			spawn_delay = 0.9 / note_queue[current_note].real_speed

		if (relative) > spawn_delay:
			break

		spawn_note(current_note)
		current_note += 1


func spawn_note(id: int) -> void:
	if note_queue.size() < id:
		return

	var note: Note = note_queue[id] as Note
	if note.player <= connected_fields.size():
		var field: = connected_fields[note.player]
		if is_instance_valid(field):
			note.notefield = field
			if note.column < field.key_count:
				note.scroll = field.scroll_mods[note.column]
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
	if is_instance_valid(note.notefield):
		note.object.visible = note.receptor.visible and note.notefield.visible
	note.object.set("note", note)
	add_child(note.object)


func connect_notefield(new_field: NoteField) -> void:
	connected_fields.append(new_field)


func disconnect_notefield(field: NoteField) -> void:
	if connected_fields.find(field) != -1:
		connected_fields.erase(field)
