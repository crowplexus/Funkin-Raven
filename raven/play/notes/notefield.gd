class_name NoteField extends Node2D

@export var is_cpu: bool = true
@export var controls: PackedStringArray = ["note_l", "note_d", "note_u", "note_r"]
@export var handle_input: bool = true
@export var debug: bool = false

var hit_behaviour: Callable = func(note: Note) -> void:
	if note == null or note.was_hit: return
	note.was_hit = true
	note.on_hit()
	if not note.is_sustain:
		note.queue_free()

var miss_behaviour: Callable = func(note: Note, _dir: int) -> void:
	if note != null:
		note.missed = true
		note.on_miss()

@onready var play: = $"../../"
@onready var receptors: Node2D = $receptors
@onready var note_group: Node2D = $notes
@onready var speed: float = 1.0

func _handle_note_behaviour(note: Note) -> void:
	if is_cpu and note.rel_time <= 0.0:
		note.receptor.skin.propagate_call("enemy_hit", [note])
		hit_behaviour.call(note)
	else:
		var late_delay: float = .10 * note.receptor.speed
		var late_len: float = note.og_len * note.receptor.speed

		if note.receptor.speed < 1:
			late_delay = .15 / note.receptor.speed
			late_len /= note.receptor.speed

		if note.rel_time <= Highscore.best_judgement().timing - late_delay:
			note.is_late = true

		if not note.was_hit and note.is_late and not note.missed:
			miss_behaviour.call(note, note.data.column)
		if note.rel_time <= -(0.5 + late_len):
			note.queue_free()

func _handle_hold_behaviour(note: Note, _delta: float = 1.0) -> void:
	if not note.is_sustain or is_cpu:
		return

	# HOLD NOTES
	match note.data.s_type:
		Chart.NoteData.SustainType.ROLL:
			# TODO: implement roll sustain behaviour
			pass
		_:
			var pressed: bool = Input.is_action_pressed(controls[note.data.column])
			# Default Behaviour
			if pressed:
				note.receptor.glow_up(note.arrow.visible or note.receptor.frame_progress > 0.05)
				if Conductor.step % 1 == 0:
					if note.modulate.a != 1.0:
						note.modulate.a = 1.0
					hit_behaviour.call(note)
			# RELEASED.
			elif note.data.s_len > 0.05:
				note.hold_coyote -= 0.1 # skill issue :/
				note.modulate.a = Tools.exp_lerp(0.8, note.modulate.a, 0.5)
				if note.hold_coyote <= 0.0:
					note.was_hit = false
					note.modulate.a = 1.0
					note.position.y = note.receptor.position.y
					note.arrow.visible = true
					note.update_sustain_len(note.og_len)
					miss_behaviour.call(note, note.data.column)

func _unhandled_key_input(e: InputEvent) -> void:
	var key: int = match_note_key(e)
	if key == -1 or is_cpu or not handle_input:
		return

	var receptor: Receptor = receptors.get_child(key) as Receptor
	var inputs: Array = note_group.get_children().filter(func(note: Note) -> bool:
		return (note.data.column == key and not note.is_late and note.can_hit
			and not note.was_hit and not note.missed)
	)
	inputs.sort_custom(func(a: Note, b: Note) -> int: return a.data.time < b.data.time)
	if Input.is_action_just_released(controls[key]):
		receptor.become_static()

	if Input.is_action_just_pressed(controls[key]):
		if inputs.is_empty():
			if not Settings.ghost_tapping: miss_behaviour.call(null, key)
			receptor.become_ghost()
		else:
			var note: Note = inputs[0] as Note
			if note.is_sustain: # few seconds to regrab
				note.hold_coyote = 2.5 * note.data.s_len
				#print_debug("note coyote timer is ", note.hold_coyote)
			receptor.glow_up()
			hit_behaviour.call(note)

	elif e.is_released():
		receptor.reset_timer = 0.0

func match_note_key(e: InputEventKey) -> int:
	for i: int in controls.size(): if e.is_action(controls[i]):
		return i
	return -1

func set_speed(new_speed: float, dir: int = -1) -> void:
	if dir <= -1:
		speed = new_speed
		for note: Note in note_group.get_children():
			if note.is_sustain:
				note.clip_rect.size.y *= new_speed
	else:
		dir = dir % receptors.get_child_count()
		(receptors.get_child(dir) as Receptor).speed = new_speed

func set_scroll(new_scroll: int = -1, tweened: bool = false, tween_duration: float = 0.6) -> void:
	for i: Receptor in receptors.get_children():
		i.reset_scroll(new_scroll, tweened, tween_duration)

func transition(duration: float = -1.0, out: bool = false) -> void:
	if duration == -1.0: duration = Conductor.crotchet * 0.001

	for i: int in receptors.get_child_count():
		var easing: = Tween.EASE_IN if not out else Tween.EASE_OUT
		var receptor: Receptor = receptors.get_child(i) as Receptor
		if receptor.skin.propagate_call("spawn_transition") == 0:
			continue

		var og_mod: float = receptor.modulate.a
		if not out: receptor.modulate.a = 0.0

		create_tween().set_ease(easing) \
		.tween_property(receptor, "modulate:a", og_mod if not out else 0.0, duration) \
		.set_delay((0.5 * Conductor.crotchet) * i)

func clear_notes() -> void:
	for note: Note in note_group.get_children():
		note.queue_free()
