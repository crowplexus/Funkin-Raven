class_name NoteField extends Node2D

@export var is_cpu: bool = true
@export var controls: PackedStringArray = ["note_l", "note_d", "note_u", "note_r"]
@export var handle_input: bool = true
@export var debug: bool = false

var hit_behavior: Callable = func(note: Note):
	if note == null or note.was_hit: return
	note.was_hit = true
	note.on_hit()
	if not note.is_sustain and not note.prevent_disposal:
		note.queue_free()

var miss_behavior: Callable = func(note: Note, _dir: int):
	if note != null:
		note.missed = true
		note.on_miss()

@onready var play: = $"../../"
@onready var receptors: Node2D = $receptors
@onready var note_group: Node2D = $notes
@onready var speed: float = 1.0

func _process(_delta: float):
	if not is_cpu: for note: Note in note_group.get_children():
		if note.was_hit and note.is_sustain:
			var dir: int = note.data.dir % receptors.get_child_count()
			var receptor: Receptor = (receptors.get_child(dir) as Receptor)
			
			if Input.is_action_pressed(controls[dir]) and Conductor.step % 2 == 0:
				receptor.play_anim("confirm", true)
				self.hit_behavior.call(note)
				if note.data.s_len < 0.0: break
			
			elif not Input.is_action_pressed(controls[dir]):
				if note.data.s_len > 0.03:
					note.is_late = true
					miss_behavior.call(note, dir)
					note.was_hit = false
					break

func _unhandled_key_input(e: InputEvent):
	var key: int = match_note_key(e)
	if key == -1 or is_cpu or not handle_input:
		return
	
	var receptor: Receptor = receptors.get_child(key) as Receptor
	var inputs: Array = note_group.get_children().filter(func(note: Note):
		return (note.data.dir == key and not note.is_late and note.can_hit
			and not note.was_hit and not note.missed)
	)
	inputs.sort_custom(func(a: Note, b: Note): return a.data.time < b.data.time)
	if Input.is_action_just_released(controls[key]):
		receptor.play_anim("static", true)
	
	if Input.is_action_just_pressed(controls[key]):
		if inputs.is_empty():
			if not Settings.ghost_tapping: miss_behavior.call(null, key)
			if receptor._last_anim != "confirm": receptor.play_anim("press", true)
		else:
			receptor.play_anim("confirm", true)
			hit_behavior.call(inputs[0] as Note)
	
	elif e.is_released():
		receptor.reset_timer = 0.0

func match_note_key(e: InputEventKey) -> int:
	for i in controls.size(): if e.is_action(controls[i]):
		return i
	return -1

func set_speed(new_speed: float, dir: int = -1):
	if dir <= -1: speed = new_speed
	else:
		dir = dir % receptors.get_child_count()
		(receptors.get_child(dir) as Receptor).speed = new_speed

func set_scroll(new_scroll: int = -1, tweened: bool = false, tween_duration: float = 0.6):
	for i: Receptor in receptors.get_children():
		i.reset_scroll(new_scroll, tweened, tween_duration)

func transition(duration: float = -1.0, out: bool = false):
	if duration == -1.0: duration = Conductor.beatc * 0.001
	
	for i: int in receptors.get_child_count():
		var easing: = Tween.EASE_IN if not out else Tween.EASE_OUT
		var receptor: Receptor = receptors.get_child(i) as Receptor
		var og_mod: float = receptor.modulate.a
		if not out: receptor.modulate.a = 0.0
		
		create_tween().set_ease(easing) \
		.tween_property(receptor, "modulate:a", og_mod if not out else 0.0, duration) \
		.set_delay((0.5 * Conductor.beatc) * i)

func clear_notes():
	for note: Note in note_group.get_children():
		note.queue_free()
