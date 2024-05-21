class_name NoteSpawner extends Node

const NOTE_TYPES: Dictionary = {
	"normal": preload("res://raven/play/notes/types/default.tscn")
}

var note_list: Array[Chart.NoteData] = []
var linked_fields: Array[NoteField] = []
var current_note: Chart.NoteData:
	get: return note_list[note_index]
var note_index: int = 0

func _ready() -> void:
	set_process_input(false)
	enable_operate()

func enable_operate() -> void:
	set_process(note_list.size() != 0)

func _process(_delta: float) -> void:
	call_deferred_thread_group("invoke_notes")

func invoke_notes() -> void:
	if not Conductor.active or note_list.size() == 0:
		return

	while note_index < note_list.size():
		var notefield: = linked_fields[current_note.lane] as NoteField
		var receptor: = notefield.receptors.get_child(current_note.column) as Receptor

		if notefield == null or receptor == null:
			note_index += 1
			break

		var delay: float = 0.9 * receptor.speed
		if receptor.speed < 1: delay /= receptor.speed

		if (current_note.time + Settings.note_offset - Conductor.time) > delay:
			break

		var type: StringName = current_note.type
		if not NOTE_TYPES.has(type) or NOTE_TYPES[type] == null:
			type = "normal"

		var new_note: = NOTE_TYPES[type].instantiate() as Note
		new_note.data.merge(current_note.to_dictionary())
		new_note.receptor = receptor
		notefield.note_group.add_child(new_note)
		note_index += 1
