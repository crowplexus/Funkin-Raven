extends Control

enum AdjustMode { KEYBIND, OFFSET }

var hitsounds: Array[AudioStream] = [
	load("res://assets/audio/sfx/menu/hitsound1.ogg"),
	load("res://assets/audio/sfx/menu/hitsound2.ogg"),
]

var menu_mode: = AdjustMode.KEYBIND

@onready var instructions_label: Label = $"instructions"

#region KEYBINDS

@onready var field: NoteField = $"field"

var note: int = 0
var player: int = 0
var binding: bool = false
var exit_callback: Callable = func() -> void: pass

var forbidden_keycodes: Array[Key] = [
	KEY_ESCAPE, KEY_ENTER, KEY_F7, KEY_PRINT
]
var temp_keybinds: Array = []
var instructions: String

#endregion

#region OFFSET

@onready var offset_bar: ProgressBar = $"offset/bar"
@onready var offset_label: Label = $"offset/bar/label"

var fake_time: float = 0.0:
	get: return fake_time
var temp_offset: float = 0.0
var fake_notes: Array[Chart.NoteData] = [
	Chart.NoteData.make(1, 0),
	Chart.NoteData.make(2, 1),
	Chart.NoteData.make(3, 2),
	Chart.NoteData.make(4, 3),
]
var current_note: int = 0
var _prev_beat: int = 0

#endregion

func _ready() -> void:
	if $"../" != null and $"../" is CanvasItem:
		self.top_level = true
		self.z_index = 10
		$"../".modulate.v = 0.5

	instructions = instructions_label.text
	fake_time = fake_notes.front().time + Settings.note_offset
	temp_keybinds = Settings.keybinds.duplicate()
	temp_offset = Settings.note_offset

	update_mode()
	update_offset_bar()
	update_selected_note()
	update_text()

func _process(delta: float) -> void:
	if menu_mode == AdjustMode.OFFSET:
		call_deferred_thread_group("invoke_notes")
		for the_note: Note in field.note_group.get_children():
			var rel_time: float = maxf(0, (the_note.data.time + temp_offset) - fake_time)
			var receptor: = field.receptors.get_child(the_note.data.column) as Receptor
			the_note.position = receptor.position
			the_note.position.y += rel_time * (800 * absf(receptor.speed)) / absf(receptor.scale.y) * -1
			if rel_time <= 0.0:
				receptor.glow_up(true)
				receptor.reset_timer = 0.3
				the_note.queue_free()

		if fake_time > (fake_notes.back().time + temp_offset):
			_prev_beat = 0
			current_note = 0
			fake_time = (fake_notes.front().time + temp_offset) - 10
		fake_time += delta

		var beat: int = floori(Conductor.time_to_beat(fake_time, 100.0))
		if beat > _prev_beat:
			on_beat(beat)
			_prev_beat = beat

func invoke_notes() -> void:
	if menu_mode != AdjustMode.OFFSET or fake_notes.size() == 0:
		return

	while current_note < fake_notes.size():
		var note_data: Chart.NoteData = fake_notes[current_note]
		var receptor: = field.receptors.get_child(note_data.column) as Receptor
		if field == null or receptor == null:
			current_note += 1
			break

		var time: float = (fake_notes[current_note].time + temp_offset) - fake_time
		if time > (1.5 / receptor.speed):
			break

		var new_note: = NoteSpawner.NOTE_TYPES["normal"].instantiate() as Note
		new_note.data.merge(fake_notes[current_note].to_dictionary())
		new_note.data.debug = true
		new_note.receptor = receptor
		field.note_group.add_child(new_note)
		current_note += 1

func _exit_tree() -> void:
	if $"../" != null and $"../" is CanvasItem:
		$"../".modulate.v = 1.0

	Settings.keybinds = temp_keybinds
	Settings.note_offset = temp_offset
	exit_callback.call()

func _unhandled_key_input(e: InputEvent) -> void:
	if not e.pressed: return

	if Input.is_action_just_pressed("ui_cancel"):
		queue_free()

	var q_pressed: bool = Input.is_key_label_pressed(KEY_Q)
	var e_pressed: bool = Input.is_key_label_pressed(KEY_E)

	if q_pressed or e_pressed:
		update_mode(-1 if q_pressed else 1)
	else:
		match menu_mode:
			AdjustMode.OFFSET:
				var axis: int = int( Input.get_axis("ui_left", "ui_right") )
				var multiplier: float = 0.001
				if Input.is_key_label_pressed(KEY_SHIFT): multiplier = 0.01
				if axis:
					temp_offset = clampf(temp_offset + multiplier * axis, -1.0, 1.0)
					fake_time = fake_notes.front().time + temp_offset
					update_offset_bar()

				elif Input.is_key_label_pressed(KEY_R):
					temp_offset = 0.0
					fake_time = fake_notes.front().time + temp_offset
					update_offset_bar()

			AdjustMode.KEYBIND:
				if not binding:
					var lr_diff: int = int( Input.get_axis("ui_left", "ui_right") )
					var ud_diff: int = int( Input.get_axis("ui_up", "ui_down") )
					if lr_diff != 0: update_selected_note(lr_diff)
					if ud_diff != 0: update_selected_player(ud_diff)

					if Input.is_action_just_pressed("ui_accept"):
						binding = true
						field.receptors.get_child(note).glow_up(true)
				else:
					var prevent: bool = false
					for i: Key in forbidden_keycodes:
						if e.keycode == i:
							prevent = true
							break

					if not prevent:
						temp_keybinds[player][note] = OS.get_keycode_string(e.keycode)
					field.receptors.get_child(note).become_static(true)
					binding = false
					update_text()

func on_beat(beat: int) -> void:
	if menu_mode == AdjustMode.OFFSET:
		SoundBoard.play_sfx(hitsounds[1 if beat % 2 == 0 else 0])

func update_selected_note(new_note: int = 0) -> void:
	if new_note != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	note = wrapi(note + new_note, 0, field.receptors.get_child_count())
	update_receptor_highlight(note)

func update_selected_player(new_player: int = 0) -> void:
	if new_player != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	player = wrapi(player + new_player, 0, temp_keybinds.size())
	update_text()

func update_receptor_highlight(dir: int = -1) -> void:
	for receptor: Receptor in field.receptors.get_children():
		var i: int = receptor.get_index()
		receptor.modulate.v = 0.4 if (i != dir and dir != -1) else 1.0

func update_text() -> void:
	match menu_mode:
		AdjustMode.OFFSET:
			instructions_label.text = "- Note Offset -\n"
			instructions_label.text += "Left/Right - Change Offset + SHIFT to Go Faster"
			instructions_label.text += "\nR to Reset Offset back to 0ms"
			instructions_label.text += "\nQ/E - Change Modes"
		AdjustMode.KEYBIND:
			var base: String = instructions
			base += "Q/E - Change Modes\n"
			for i: int in temp_keybinds.size():
				var keybinds: Array = temp_keybinds[i]
				var begin: String = "\n> " if i == player else "\n"
				base += begin + "P%s Binds: %s" % [ i+1, str(keybinds).replace('"', "")]
			instructions_label.text = base

func update_mode(new_mode: int = 0) -> void:
	menu_mode = wrapi(menu_mode + new_mode, 0, AdjustMode.keys().size())

	match menu_mode:
		AdjustMode.KEYBIND:
			_prev_beat = 0
			current_note = 0
			fake_time = 0
			update_receptor_highlight(note)
			$"keybinds".visible = true
			$"offset".visible = false
		AdjustMode.OFFSET:
			field.clear_notes()
			update_receptor_highlight(-1)
			$"keybinds".visible = false
			$"offset".visible = true
	update_text()

func update_offset_bar() -> void:
	offset_bar.value = temp_offset * 1000.0
	offset_label.text = str(snappedf(temp_offset * 1000.0, 0.01)) + "ms"
