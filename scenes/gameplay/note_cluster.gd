extends Node2D

signal note_incoming(note: NoteData)

const NOTE_KIND_OBJECTS: Dictionary = {
	"normal": preload("res://scenes/gameplay/notes/normal.tscn"),
}

@export var note_queue: Array[NoteData] = []
@export var current_note: int = 0


func _ready() -> void:
	if is_instance_valid(Chart.global):
		note_queue = Chart.global.notes.duplicate()


func _process(_delta: float) -> void:
	if not note_queue.is_empty():
		call_deferred_thread_group("_spawn_notes")
		for note: NoteData in note_queue:
			if not is_instance_valid(note.object):
				continue

			var rel_time: float = note.time - Conductor.time
			note.object.position = note.initial_pos
			#note.object.position.x = note.initial_position.x + (90 * note.object.scale.x) * note.column
			note.object.position.y += rel_time * (400.0 * absf(note.speed)) / absf(note.object.scale.y)

			if not note.as_player and rel_time <= 0.0:
				note.hit_flag = 2
				if is_instance_valid(note.object):
					note.object.free()
				continue

			if is_instance_valid(note.object) and rel_time < -.15 and note.hit_flag != -1:
				note.hit_flag = -1
				note.object.free()


func _spawn_notes() -> void:
	var time_rel: float = note_queue[current_note].time - Conductor.time
	var spawn_delay: float = 0.9 * note_queue[current_note].speed
	if note_queue[current_note].speed < 1.0:
		spawn_delay = 0.9 / note_queue[current_note].speed

	while time_rel < spawn_delay and current_note < note_queue.size() - 1:
		var note: NoteData = note_queue[current_note]
		note_incoming.emit(note)
		if not is_instance_valid(note.object):
			var kind: StringName = "normal"
			if note.kind in NOTE_KIND_OBJECTS:
				kind = note.kind
			note.object = NOTE_KIND_OBJECTS[kind].instantiate()
			note.object.position.y = INF

		if is_instance_valid(note.object):
			add_child(note.object)
		current_note += 1
