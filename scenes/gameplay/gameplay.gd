extends Node2D

var music: AudioStreamPlayer

@onready var ui_layer: CanvasLayer = $"ui_layer"
@onready var note_cluster: Node2D = $"ui_layer/note_cluster"
@onready var fields: Control = $"ui_layer/fields"


func _ready() -> void:
	await RenderingServer.frame_post_draw

	var songs_path: String = "res://assets/songs/%s/" % Chart.global.song_info.folder

	# TEMPORARY SETUP FOR TRACKS #
	for i: String in DirAccess.get_files_at(songs_path):
		if i.get_extension() == "ogg":
			if music == null and i.to_lower().find("inst") != -1:
				music = AudioStreamPlayer.new()
				music.stream = load(songs_path + "%s" % i)
				music.name = "%s" % i
				music.bus = "BGM"
				add_child(music)

			if music != null:
				var vocals: = AudioStreamPlayer.new()
				vocals.name = "%s" % i.replace(i.get_extension(), "")
				vocals.stream = load(songs_path + "%s" % i)
				vocals.bus = music.bus
				music.add_child(vocals)

	##################

	var player: Player = Player.new()
	player.note_queue = note_cluster.note_queue
	player.note_hit.connect(update_score_text)
	note_cluster.note_incoming.connect(player_note_spawned)
	fields.get_child(0).make_playable(player)
	update_score_text.call_deferred(null)

	Conductor.time = -0.5


func _process(_delta: float) -> void:
	Conductor.time += _delta
	if Conductor.time >= 0.0 and is_instance_valid(music) and not music.playing:
		music.play(0.0)
		for track: AudioStreamPlayer in music.get_children():
			track.play(0.0)

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
