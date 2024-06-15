extends Node

@onready var bgm_player: AudioStreamPlayer = $"bgm_player"


func play_bgm(bgm_stream: AudioStream, volume: float = 0.7) -> void:
	if not is_instance_valid(bgm_stream):
		return

	bgm_player.volume_db = linear_to_db(volume)
	bgm_player.name = bgm_stream.resource_path.get_file().get_basename()
	bgm_player.stream = bgm_stream

	bgm_player.play(0.0)


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
