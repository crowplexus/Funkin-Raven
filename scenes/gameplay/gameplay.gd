extends Node2D

var music: AudioStreamPlayer

@onready var ui_layer: CanvasLayer = $"ui_layer"
@onready var note_cluster: Node2D = $"ui_layer/note_cluster"
@onready var fields: Control = $"ui_layer/fields"

var _need_to_play_music: bool = false

func _ready() -> void:
	await RenderingServer.frame_post_draw

	var track_path: String = "res://assets/songs/%s/" % Chart.global.song_info.folder
	var in_variation: bool = Chart.global.song_info.difficulty.variation.is_empty()

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

	if not Preferences.botplay:
		var player: Player = Player.new()
		player.note_queue = note_cluster.note_queue
		player.note_hit.connect(update_score_text)
		note_cluster.note_incoming.connect(player_note_spawned)
		fields.get_child(0).make_playable(player)
		update_score_text.call_deferred(null)

	Conductor.time = -0.5


func _process(_delta: float) -> void:
	Conductor.time += _delta
	if Conductor.time >= 0.0 and _need_to_play_music:
		music.play(0.0)
		for track: AudioStreamPlayer in music.get_children():
			track.play(0.0)
		_need_to_play_music = false

	#if is_instance_valid(music) and music.playing:
	#	Conductor.time = music.get_playback_position() + AudioServer.get_time_since_last_mix()
	#	#print_debug(Conductor.time)

func update_score_text(_hit_result: NoteData.HitResult) -> void:
	for field: CanvasItem in fields.get_children():
		if is_instance_valid(field.player):
			var id: int = field.get_index() + 1
			ui_layer.get_node("status_%s" % str(id)).text = field.player.mk_stats_string()


func player_note_spawned(note: NoteData) -> void:
	for field: CanvasItem in fields.get_children():
		if note.player == field.get_index():
			var receptor: CanvasItem = field.receptors.get_child(note.column)
			note.initial_pos = receptor.global_position
			note.initial_pos.x -= note_cluster.global_position.x
			note.initial_pos.y -= note_cluster.position.y
			if is_instance_valid(field.player):
				note.as_player = true
