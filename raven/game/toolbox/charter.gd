extends Node2D

var music: AudioStreamPlayer

@onready var board = $board
@onready var lanes = $board/lanes
@onready var info = $text/info
@onready var selection = $selection
@onready var select_panel = $selection/panel
@onready var window = get_window()

func _ready():
	if PlayField.play_manager == null:
		PlayField.play_manager = PlayManager.new()
	
	if PlayField.chart == null:
		PlayField.chart = Chart.request("dadbattle", "hard")
		PlayField.song_data = FreeplaySong.new()
		PlayField.song_data.name = "Dadbattle"
		PlayField.song_data.folder = "dadbattle"
		PlayField.play_manager.difficulty = "hard"
	
	FPS.get_node("text_control").modulate.a = 0.3
	
	Conductor._reset()
	Conductor.beatf = 0.0
	Conductor.stepf = 0.0
	Conductor.barf = 0.0
	
	var music_path: String = Chart.get_chart_path(PlayField.song_data.folder)+"/audio"
	for stream: AudioStream in SoundBoard.get_streams_at(music_path):
		stream.loop = false
		# Master Track
		if music == null and stream.resource_name.to_lower().find("inst") != -1:
			music = AudioStreamPlayer.new()
			music.stream = stream
		# Children Tracks
		elif music != null:
			var vocal: AudioStreamPlayer = AudioStreamPlayer.new()
			vocal.stream = stream
			music.add_child(vocal)
	add_child(music)
	
	info.text = "%s"%PlayField.song_data.name
	if PlayField.chart.metadata != null and PlayField.chart.metadata.get_authors() != "":
		info.text+="\nBy: %s"%PlayField.chart.metadata.get_authors()
	
	board.on_ready()

func _exit_tree():
	FPS.get_node("text_control").modulate.a = 1.0

func _process(delta: float):
	board.self_modulate.a = Tools.lerp_fix(board.self_modulate.a, 1.0 - float(Conductor.active) * 0.5, delta, 5.0)
	
	if selection.position.x >= 0:
		var size = window.get_mouse_position() - selection.position
		select_panel.position.x = minf(size.x, 0.0)
		select_panel.position.y = minf(size.y, 0.0)
		select_panel.size = abs(size)
	
	if Conductor.active:
		Conductor.time = music.get_playback_position() + AudioServer.get_time_since_last_mix()
		board.call_deferred_thread_group("spawn_notes", false)
		board.call_deferred_thread_group("update")

func _input(event):
	if not event is InputEventMouseButton: return
	
	var wheel_axis = -int(event.button_index == MOUSE_BUTTON_WHEEL_UP) + int(event.button_index == MOUSE_BUTTON_WHEEL_DOWN)
	if wheel_axis != 0 and not Conductor.active and not event.is_released():
		var mult = 1 + 3 * int(Input.is_key_label_pressed(KEY_SHIFT))
		Conductor.time = (floorf((Conductor.time + 0.001) / board.snap_inc) + wheel_axis * mult) * board.snap_inc # add an extra milisecond cuz flooring can be wacky sometimes.
		Conductor.time = clampf(Conductor.time, 0.0, 99999.0)
		board.call_deferred_thread_group("spawn_notes", wheel_axis < 0)
		Conductor.active = true
		Conductor._process(0.0)
		Conductor.active = false
		board.call_deferred_thread_group("update")
		
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			selection.position = window.get_mouse_position()
		elif event.is_released():
			select_panel.size.x = maxf(select_panel.size.x, 1.0)
			select_panel.size.y = maxf(select_panel.size.y, 1.0)
			
			if not Input.is_key_label_pressed(KEY_CTRL):
				for note in board.selected_notes:
					note.selected = false
				board.selected_notes.clear()
				
			var panel_rect = select_panel.get_global_rect()
			for lane:NoteField in lanes.get_children():
				for note:Note in lane.note_group.get_children():
					if panel_rect.intersects(get_note_rect(note), true) and not board.selected_notes.has(note):
						board.selected_notes.append(note)
						note.selected = true
						
			select_panel.size = Vector2.ZERO
			selection.position.x = -99

func get_note_rect(note:Note):
	var size = abs((note.arrow.sprite_frames.get_frame_texture(note.arrow.animation, note.arrow.frame).get_size() * note.arrow.global_scale).rotated(note.arrow.rotation))
	var rect = Rect2(note.arrow.global_position, size)
	if note.arrow.centered:
		rect.position -= size * 0.5
	return rect

func _unhandled_key_input(e: InputEvent):
	if e.pressed: match e.keycode:
		KEY_ESCAPE: Tools.switch_scene(load("res://raven/game/gameplay.tscn"))
		KEY_SPACE:
			Conductor.active = not Conductor.active
			if not Conductor.active:
				music.stop()
				for track: AudioStreamPlayer in music.get_children():
					track.stop()
			else:
				music.play(Conductor.time)
				for track: AudioStreamPlayer in music.get_children():
					track.play(Conductor.time)
				lanes.start_notes()
		KEY_Q, KEY_E:
			for note in board.selected_notes:
				var hold_mult = (-int(e.keycode == KEY_Q) + int(e.keycode == KEY_E)) * (1 + 3 * int(Input.is_key_label_pressed(KEY_SHIFT)))
				note.data.s_len = maxf(note.data.s_len + board.snap_inc * hold_mult, 0.0)
				note.clip_rect.size.y = (board.note_spacing * (note.data.s_len / Conductor.beatc)) / note.global_scale.y
		KEY_Z, KEY_X:
			board.note_spacing *= 1.25 - 0.75 * (e.keycode - 89)
		KEY_LEFT, KEY_RIGHT:
			if not Conductor.active:
				board.cur_snap += (e.keycode - 4194320)
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8: # long case >:3
			board.try_add(e.keycode - 49)
		KEY_DELETE:
			for note in board.selected_notes:
				board.note_list.erase(note.data)
				note.queue_free()
			board.selected_notes.clear()
