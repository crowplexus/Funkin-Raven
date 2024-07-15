extends Node

@onready var bgm_player: AudioStreamPlayer = $"bgm_player"
var current_bgm: StringName
var bgm_fade_twn: Tween

func play_bgm(bgm_stream: AudioStream, volume: float = 0.7, pitch_scale: float = 1.0, looped: bool = true) -> void:
	if not is_instance_valid(bgm_stream):
		return

	bgm_player.stream = bgm_stream
	bgm_player.stream.loop = looped
	bgm_player.volume_db = linear_to_db(volume)
	bgm_player.stream.resource_name = bgm_stream.resource_path.get_file().get_basename()
	bgm_player.pitch_scale = pitch_scale
	bgm_player.play(0.0)

	current_bgm = bgm_stream.resource_path.get_file().get_basename()

func fade_bgm(from: float = 0.001, to: float = 0.7, duration_to: float = 4.0) -> void:
	if not bgm_player.playing:
		push_warning("Fade requested, but no BGM music is playing in the soundboard")

	cancel_bgm_fade_tween()
	bgm_fade_twn = create_tween().set_ease(Tween.EASE_IN)
	bgm_fade_twn.set_parallel(true)

	if SoundBoard.bgm_player.volume_db != linear_to_db(from):
		SoundBoard.bgm_player.volume_db = linear_to_db(from)

	bgm_fade_twn.tween_property(SoundBoard.bgm_player, "volume_db", linear_to_db(to), duration_to)

func cancel_bgm_fade_tween() -> void:
	if bgm_fade_twn:
		bgm_fade_twn.stop()

func play_sfx(sound: AudioStream, volume: float = 0.7, pitch_scale: float = 1.0) -> void:
	if not sound:
		return

	var sfx: = AudioStreamPlayer.new()
	sfx.volume_db = linear_to_db(volume)
	sfx.name = sound.resource_path.get_file().get_basename()
	sfx.finished.connect(sfx.queue_free)
	sfx.pitch_scale = pitch_scale
	sfx.stream = sound
	sfx.bus = "SFX"
	add_child(sfx)

	#print_debug(sfx.name)
	sfx.play(0.0)

func get_bgm_pos() -> float:
	if SoundBoard.is_bgm_playing():
		return SoundBoard.bgm_player.get_playback_position()
	return 0.0

func get_bgm_volume(db: bool = false) -> float:
	if db: return SoundBoard.bgm_player.volume_db
	else: return db_to_linear(SoundBoard.bgm_player.volume_db)

func is_bgm_playing() -> bool:
	return is_instance_valid(SoundBoard.bgm_player) and SoundBoard.bgm_player.playing

func stop_bgm() -> void:
	if SoundBoard.bgm_player.playing:
		SoundBoard.bgm_player.stop()
