extends Node

@onready var bgm_player: AudioStreamPlayer = $"bgm_player"
var current_bgm: StringName
var bgm_fade_twn: Tween


func play_bgm(bgm_stream: AudioStream, volume: float = 0.7) -> void:
	if not is_instance_valid(bgm_stream):
		return

	bgm_player.volume_db = linear_to_db(volume)
	bgm_player.name = bgm_stream.resource_path.get_file().get_basename()
	bgm_player.stream = bgm_stream
	bgm_player.stream.loop = true
	bgm_player.play(0.0)

	current_bgm = bgm_stream.resource_path.get_file().get_basename()


func fade_bgm(from: float = 0.001, to: float = 0.7, duration_to: float = 4.0) -> void:
	if not bgm_player.playing:
		push_warning("Fade requested, but no BGM music is playing in the soundboard")

	cancel_bgm_fade_tween()

	bgm_fade_twn = create_tween().set_ease(Tween.EASE_IN)
	bgm_fade_twn.set_parallel(true)

	if bgm_player.volume_db != linear_to_db(from):
		SoundBoard.bgm_player.volume_db = linear_to_db(from)

	bgm_fade_twn.tween_property(SoundBoard.bgm_player, "volume_db", linear_to_db(to), duration_to)


func cancel_bgm_fade_tween() -> void:
	if is_instance_valid(bgm_fade_twn):
		bgm_fade_twn.stop()


func play_sfx(sound: AudioStream, volume: float = 0.7) -> void:
	if not is_instance_valid(sound):
		return

	var sfx: = AudioStreamPlayer.new()
	sfx.volume_db = linear_to_db(volume)
	sfx.name = sound.resource_path.get_file().get_basename()
	sfx.finished.connect(sfx.queue_free)
	sfx.stream = sound
	add_child(sfx)

	#print_debug(sfx.name)
	sfx.play(0.0)

func is_bgm_playing() -> bool:
	return is_instance_valid(SoundBoard.bgm_player) and SoundBoard.bgm_player.playing

func stop_bgm() -> void:
	if SoundBoard.bgm_player.playing:
		SoundBoard.bgm_player.stop()
