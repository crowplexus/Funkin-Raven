extends Node2D

signal note_incoming(note: Note)

const NOTE_KIND_OBJECTS: Dictionary = {
	"normal": preload("res://scenes/gameplay/notes/normal.tscn"),
}

@export var connected_fields: Array[NoteField] = []
@export var note_queue: Array[Note] = []
@export var current_note: int = 0


func _ready() -> void:
	if is_instance_valid(Chart.global):
		note_queue = Chart.global.notes.duplicate()


func _process(delta: float) -> void:
	await RenderingServer.frame_post_draw
	if note_queue.size() != 0:
		spawn_notes.call_deferred()
		if get_child_count() != 0:
			move_note_objects(delta)


func move_note_objects(_delta: float) -> void:
	for note: Note in note_queue:
		if not is_instance_valid(note) or note.finished:
			continue

		var rel_time: float = note.time - Conductor.time
		var note_scale: float = 0.7

		if is_instance_valid(note.object) and note.moving:
			var real_position: Vector2 = Vector2.ZERO
			if is_instance_valid(note.notefield):
				real_position = note.receptor.global_position

			var scroll_speed: float = note.speed
			match Preferences.scroll_speed_behaviour:
				1: scroll_speed += Preferences.scroll_speed
				2: scroll_speed  = Preferences.scroll_speed
			note.object.global_position = note.initial_pos + real_position
			note.object.position.x *= note.scroll.x
			#note.object.position.x = note.initial_position.x + (90 * note.object.scale.x) * note.column
			note.object.position.y += rel_time * (400.0 * absf(scroll_speed)) / absf(note_scale) * note.scroll.y
			#note.object.position *= note.scroll


func spawn_notes() -> void:
	while current_note != note_queue.size():
		var note: Note = note_queue[current_note]
		var time_rel: float = note.time - Conductor.time
		var spawn_delay: float = 0.9 * note.speed
		if note_queue[current_note].speed < 1.0:
			spawn_delay = 0.9 / note.speed

		if time_rel > spawn_delay:
			break

		if note.player <= connected_fields.size():
			var field: = connected_fields[note.player]
			note.notefield = field
			if note.column < field.scroll_mods.size():
				note.scroll = field.scroll_mods[note.column]

		note_incoming.emit(note)
		if not is_instance_valid(note.object):
			var kind: StringName = "normal"
			if note.kind in NOTE_KIND_OBJECTS:
				kind = note.kind
			note.object = NOTE_KIND_OBJECTS[kind].instantiate()
			note.object.position.y = INF

		if is_instance_valid(note.object):
			if note.object.get("note") == null:
				note.object.set("note", note)
			add_child(note.object)
		current_note += 1


func animate_receptor(tn: Note) -> void:
	if not is_instance_valid(tn.notefield):
		return

	var delay: float = (0.5 * Conductor.crotchet) + tn.hold_length
	tn.notefield.call_deferred("play_glow", tn.column)
	await get_tree().create_timer(delay).timeout
	tn.notefield.call_deferred("play_static", tn.column)


func connect_notefield(new_field: NoteField) -> void:
	if is_instance_valid(new_field):
		connected_fields.append(new_field)


func disconnect_notefield(field: NoteField) -> void:
	if connected_fields.find(field) != -1:
		connected_fields.erase(field)
