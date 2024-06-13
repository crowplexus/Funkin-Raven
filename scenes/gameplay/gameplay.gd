extends Node2D

#region Scene Nodes

@onready var camera: Camera2D = $"camera"
@onready var ui_layer: CanvasLayer = $"ui_layer"
@onready var status_label: Label = $"ui_layer/status_label"
@onready var hit_result_label: Label = $"ui_layer/judge"
@onready var note_cluster: Node2D = $"ui_layer/note_cluster"
@onready var fields: Control = $"ui_layer/fields"

#endregion
#region Local Variables

var music: AudioStreamPlayer
var camera_beat_interval: int = 2
var initial_camera_zoom: Vector2 = Vector2.ONE
var initial_ui_zoom: Vector2 = Vector2.ONE
var _need_to_play_music: bool = true

#endregion
#region Node2D Functions

func _ready() -> void:
	await RenderingServer.frame_post_draw

	Conductor.active = false
	Conductor.time = -0.5

	init_music()
	init_camera()
	if not Preferences.botplay:
		init_players(1)

	initial_ui_zoom = ui_layer.scale

	# Connect Signals
	Conductor.beat_reached.connect(on_beat_reached)
	note_cluster.note_incoming.connect(position_notes)
	note_cluster.note_fly_over.connect(miss_fly_over)

	await RenderingServer.frame_post_draw
	Conductor.active = true


func _process(delta: float) -> void:
	process_conductor(delta)
	# reset camera zooming #
	if camera.zoom != initial_camera_zoom:
		camera.zoom = Vector2(
			lerpf(initial_camera_zoom.x, camera.zoom.x, exp(-delta * 40)),
			lerpf(initial_camera_zoom.y, camera.zoom.y, exp(-delta * 40))
		)

	if ui_layer.scale != initial_ui_zoom:
		# same as above but for UI
		pass

func _unhandled_key_input(e: InputEvent) -> void:
	if e.is_pressed():
		match e.keycode:
			KEY_ENTER:
				if not get_tree().paused:
					var ow: Control = load("res://scenes/ui/options_window.tscn").instantiate()
					ow.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
					#ow.pivot_offset = Vector2(1280/2,720/2)
					ow.z_index = 5
					ui_layer.add_child(ow)
					get_tree().paused = true


func _exit_tree() -> void:
	note_cluster.note_incoming.disconnect(position_notes)
	note_cluster.note_fly_over.disconnect(miss_fly_over)

	for i: int in fields.get_child_count():
		var field: NoteField = fields.get_child(i)
		if is_instance_valid(field.player):
			field.player.note_hit.disconnect(update_score_text)
			field.player.note_hit.disconnect(show_combo_temporary)

	Conductor.beat_reached.disconnect(on_beat_reached)

#endregions
#region Gameplay Setup

func init_players(player_count: int = 1) -> void:
	for i: int in fields.get_child_count():
		if i >= player_count:
			break

		var field: NoteField = fields.get_child(i)
		var player: Player = Player.new()
		player.note_queue = note_cluster.note_queue

		for j: int in player.controls.size():
			player.controls[j] += "_p%s" % str(i+1)

		player.note_hit.connect(update_score_text)
		player.note_hit.connect(show_combo_temporary)
		# send hit result so the score text updates
		var fake_result: = Note.HitResult.new()
		fake_result.player = player
		player.note_hit.emit(fake_result)
		field.make_playable(player)
		fake_result.unreference()


func init_camera(default_zoom: Vector2 = Vector2.ONE) -> void:
	camera.zoom = default_zoom
	initial_camera_zoom = camera.zoom
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 3.0


func init_music() -> void:
	# SETUP MUSIC (temporary) #

	if not is_instance_valid(Chart.global):
		return

	var track_path: String = "res://assets/songs/%s/" % Chart.global.song_info.folder
	var in_variation: bool = not Chart.global.song_info.difficulty.variation.is_empty()

	for fn: String in DirAccess.get_files_at(track_path):
		if in_variation:
			break

		if fn.get_extension() != "ogg":
			continue

		if not is_instance_valid(music):
			music = AudioStreamPlayer.new()
			music.stream = load(track_path + fn) as AudioStream
			music.name = "%s" % fn.get_basename()
			music.stream.loop = false
			music.bus = "BGM"
			add_child(music)
			continue

		var vocals: = AudioStreamPlayer.new()
		vocals.stream = load(track_path + fn) as AudioStream
		vocals.name = "%s" % fn.get_basename()
		vocals.stream.loop = false
		vocals.bus = music.bus
		music.add_child(vocals)

	_need_to_play_music = is_instance_valid(music) and not music.playing
	##################

#endregion
#region Gameplay Loop

func process_conductor(delta: float) -> void:
	if not Conductor.active:
		return

	if _need_to_play_music:
		Conductor.time += delta
		if Conductor.time >= 0.0:
			if is_instance_valid(music):
				music.play(0.0)
				for track: AudioStreamPlayer in music.get_children():
					track.play(0.0)
				_need_to_play_music = false
	elif not _need_to_play_music:
		Conductor.time = music.get_playback_position() + AudioServer.get_time_since_last_mix()


func on_beat_reached(beat: int) -> void:
	if beat % camera_beat_interval == 0:
		camera.zoom += Vector2(0.035, 0.035)

## Connected to [code]note_cluster.note_incoming[/code], Used to poisition the notes
func position_notes(note: Note) -> void:
	for field: NoteField in fields.get_children():
		if note.player == field.get_index():
			var receptor: Sprite2D = field.receptors.get_child(note.column)
			note.initial_pos = receptor.global_position
			note.initial_pos.x -= note_cluster.global_position.x
			note.initial_pos.y -= note_cluster.position.y
			if is_instance_valid(field.player):
				note.as_player = true

## Connected to [code]note_cluster.note_fly_over[/code] to handle
## missing notes by letting them fly above your notefield..
func miss_fly_over(note: Note) -> void:
	for field: NoteField in fields.get_children():
		if note.player == field.get_index() and is_instance_valid(field.player):
			field.player.apply_miss(note.column)
			var fake_result: = Note.HitResult.new()
			fake_result.player = field.player
			update_score_text(fake_result)
			fake_result.unreference()

#endregion
#region HUD Elements

var combo_tween: Tween

func update_score_text(hit_result: Note.HitResult) -> void:
	if not is_instance_valid(hit_result.player) or not is_instance_valid(status_label):
		return

	status_label.text = hit_result.player.mk_stats_string()


func show_combo_temporary(hit_result: Note.HitResult) -> void:
	if hit_result.judgment == null or hit_result.judgment.is_empty():
		return

	var hit_colour: Color = Color.DIM_GRAY
	if "color" in hit_result.judgment:
		hit_colour = hit_result.judgment.color
	elif "colour" in hit_result.judgment: # british.
		hit_colour = hit_result.judgment.colour

	hit_result_label.text = (str(hit_result.judgment.name) +
		"\nTiming: %sms" % snappedf(hit_result.hit_time, 0.001) +
		"\nCombo: %s" % hit_result.player.combo)
	hit_result_label.modulate = hit_colour

	if is_instance_valid(combo_tween):
		combo_tween.kill()

	combo_tween = create_tween().set_ease(Tween.EASE_OUT)
	combo_tween.bind_node(hit_result_label)
	combo_tween.tween_property(hit_result_label, "modulate:a", 0.0, 0.5 * Conductor.crotchet) \
	.set_delay(0.5 * Conductor.crotchet)

#endregion
