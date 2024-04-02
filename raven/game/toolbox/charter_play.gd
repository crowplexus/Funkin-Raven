extends Node2D

@onready var ms_label: Label = $"../ms_label"
@onready var plr_lane: NoteField = $player
var hit_tmr: float = 0.0

func _process(delta):
	hit_tmr -= delta * 2.0
	ms_label.modulate.a = minf(hit_tmr, 1.0)
	ms_label.position.x = 575.0 + 15.0 * maxf(hit_tmr - 2.75, 0.0) * 4.0

func start_notes():
	for note: Note in plr_lane.note_group.get_children():
		note.was_hit = note.data.time < Conductor.time

func _unhandled_key_input(e: InputEvent):
	var key: int = plr_lane.match_note_key(e)
	if not e.is_pressed() or key == -1 or not Conductor.active: return
	
	var lowest: float = Highscore.judgements[Highscore.judgements.keys().back()][1]
	var inputs: Array = plr_lane.note_group.get_children().filter(func(note: Note):
		return (note.data.dir == key and not note.was_hit and abs(note.data.time - Conductor.time) < lowest)
	)
	
	if inputs.size() == 0: return
	
	var note: Note = inputs[0]
	hit_tmr = 3.0
	note.was_hit = true
	note.modulate *= 1.5;
	ms_label.text = str(roundf((note.data.time - Conductor.time) * 100000) * 0.01) + " ms"
	get_tree().create_tween().tween_property(note, "modulate", Color.WHITE, 0.125)
