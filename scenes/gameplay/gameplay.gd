extends Node2D

@onready var ui_layer: CanvasLayer = $"ui_layer"
@onready var status_label: Label = $"ui_layer/status_label"
@onready var hit_result_label: Label = $"ui_layer/judge"
@onready var note_cluster: Node2D = $"ui_layer/note_cluster"
@onready var fields: Control = $"ui_layer/fields"

var music: AudioStreamPlayer
var _need_to_play_music: bool = false


func _ready() -> void:
	await RenderingServer.frame_post_draw

	Conductor.time = -0.5
	if not Preferences.botplay:
		setup_player(2)
	note_cluster.note_incoming.connect(position_notes)

	# SETUP MUSIC (temporary) #

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


func setup_player(player_count: int = 1) -> void:
	for i: int in fields.get_child_count():
		if i >= player_count:
			break

		var field: NoteField = fields.get_child(i)
		var player: Player = Player.new()
		player.note_queue = note_cluster.note_queue

		for j: int in player.controls.size():
			player.controls[j] += "_p%s" % str(i+1)

		player.note_hit.connect(update_score_text)
		# send hit result so the score text updates
		var fake_result: = NoteData.HitResult.new()
		fake_result.player = player
		player.note_hit.emit(fake_result)

		field.make_playable(player)


func _process(_delta: float) -> void:
	Conductor.time += _delta
	if Conductor.time >= 0.0 and _need_to_play_music:
		if is_instance_valid(music):
			music.play(0.0)
			for track: AudioStreamPlayer in music.get_children():
				track.play(0.0)
		_need_to_play_music = false

	#if is_instance_valid(music) and music.playing:
	#	Conductor.time = music.get_playback_position() + AudioServer.get_time_since_last_mix()
	#	#print_debug(Conductor.time)


func update_score_text(hit_result: NoteData.HitResult) -> void:
	if not is_instance_valid(hit_result.player) or not is_instance_valid(status_label):
		return

	status_label.text = hit_result.player.mk_stats_string()

#region Signal Functions

## Connected to [code]note_cluster.note_incoming[/code], Used to poisition the notes
func position_notes(note: NoteData) -> void:
	for field: NoteField in fields.get_children():
		if note.player == field.get_index():
			var receptor: Sprite2D = field.receptors.get_child(note.column)
			note.initial_pos = receptor.global_position
			note.initial_pos.x -= note_cluster.global_position.x
			note.initial_pos.y -= note_cluster.position.y
			if is_instance_valid(field.player):
				note.as_player = true

#endregion
