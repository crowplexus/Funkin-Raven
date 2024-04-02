extends Node

@onready var bg_tracks: AudioStreamPlayer = $sound_board
@onready var sfx_tracks: AudioStreamPlayer = $sound_player

func play_track(track: AudioStream, looped: bool = true, volume: float = 1.0, start_time: float = 0.0):
	track.loop = looped
	bg_tracks.stream = track
	bg_tracks.volume_db = linear_to_db(volume)
	if start_time > -1.0: bg_tracks.play(start_time)

func play_sfx(track: AudioStream, custom_pitch: float = 1.0, volume: float = 1.0, start_time: float = 0.0):
	var new_sound: AudioStreamPlayer = AudioStreamPlayer.new()
	new_sound.volume_db = linear_to_db(volume)
	new_sound.stream = track
	new_sound.pitch_scale = custom_pitch
	new_sound.finished.connect(new_sound.queue_free)
	sfx_tracks.add_child(new_sound)
	new_sound.play(start_time)

func play_sfx_direct(track: AudioStream, start_time: float = 0.0, volume: float = 1.0):
	sfx_tracks.stream = track
	sfx_tracks.volume_db = linear_to_db(volume)
	sfx_tracks.play(start_time)

func add_track(track: AudioStream):
	var new_track: AudioStreamPlayer = AudioStreamPlayer.new()
	new_track.stream = track
	bg_tracks.add_child(new_track)

func remove_track(track: AudioStream, free: bool = true):
	for i: AudioStreamPlayer in bg_tracks.get_children():
		if i.stream == track:
			i.stop()
			if free: i.queue_free()
			else: bg_tracks.remove_child(i)

func pause_tracks():
	bg_tracks.stream_paused = true
	for i: AudioStreamPlayer in bg_tracks.get_children():
		i.stream_paused = true

func resume_tracks():
	bg_tracks.stream_paused = false
	for i: AudioStreamPlayer in bg_tracks.get_children():
		i.stream_paused = false

func stop_tracks():
	bg_tracks.stop()
	for i: AudioStreamPlayer in bg_tracks.get_children():
		i.stop()

func stop_sounds():
	sfx_tracks.stop()
	for i: AudioStreamPlayer in sfx_tracks.get_children():
		i.stop()

func get_streams_at(directory: String):
	var streams: Array[AudioStream] = []
	var strings: Array[String] = []
	
	for file: String in DirAccess.get_files_at(directory):
		var lol: String = file.replace(".ogg", "") \
			.replace(".%s" % file.get_extension(), "")
		
		if strings.has(lol): continue # safety check
		var stream: AudioStream = null
		
		match file.get_extension():
			"import": # From Editor
				stream = load("%s/%s" % [directory, file.replace(".%s" % file.get_extension(), "") ])
			"ogg": # From User Folder
				stream = AudioStreamOggVorbis.load_from_file("%s/%s" % [directory, file])
			
		if stream != null:
			stream.resource_name = file
			if not strings.has(lol):
				strings.append(lol)
			streams.append(stream)
	
	strings.clear()
	return streams

func is_track_desynced(track1: AudioStreamPlayer, track2: AudioStreamPlayer, time: float = 0.01):
	return absf(track1.get_playback_position() - track2.get_playback_position()) > time
