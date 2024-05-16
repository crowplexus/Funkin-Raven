extends CanvasLayer

@onready var texts: Control = $"text_control"
@onready var fps_count: RichTextLabel = $"text_control/fps_count"
@onready var master_vol: ProgressBar = $"volume_tray"
@onready var preloader: ResourcePreloader = $"preloader"

var tray_twn: Tween
var game_volume_muted: bool = false
var pram: int = 0

func _ready() -> void:
	var bonk: Timer = Timer.new()
	add_child(bonk)

	update_stats()
	bonk.start(1.0)
	bonk.timeout.connect(func() -> void:
		update_stats()
		bonk.start(1.0)
	)
	master_vol.value = Settings.volume

func _unhandled_key_input(e: InputEvent) -> void:
	# debug shit temporary
	var axis: int = int(Input.get_axis("volume_down", "volume_up"))
	if axis:
		if AudioServer.is_bus_mute(0):
			game_volume_muted = false
			AudioServer.set_bus_mute(0, game_volume_muted)

		if master_vol.visible:
			Settings.volume += 5 * axis
		await RenderingServer.frame_post_draw
		show_tray()
		Settings._save_pref("volume")
		Settings._cfg.save(Settings._CONFIG_PATH)

	elif Input.is_action_just_pressed("volume_mute"):
		game_volume_muted = not game_volume_muted
		AudioServer.set_bus_mute(0, game_volume_muted)
		show_tray()

	if e.pressed: match e.keycode:
		KEY_F1: texts.visible = not texts.visible
		KEY_F3:
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))
		KEY_F5:
			SoundBoard.stop_tracks()
			SoundBoard.stop_sounds()
			if PlayField.play_manager != null:
				PlayField.play_manager.reset()
			await RenderingServer.frame_post_draw
			get_tree().paused = false
			Tools.refresh_scene(true)

func update_stats() -> void:
	var fps: float = Engine.get_frames_per_second()
	var fps_text: String = "%s FPS" %  fps
	var a_bad: bool = Settings.framerate_mode != 1 and fps <= Engine.max_fps * 0.5

	if OS.is_debug_build():
		var ram: = OS.get_static_memory_usage()
		if ram > pram: pram = ram
		fps_text += " | " + "%s / [color=GRAY]%s[/color]" % [
			String.humanize_size( int(ram)), String.humanize_size( int(pram) )]
		a_bad = a_bad or ram <= (ram * 0.5)

	fps_text += "\nF1 to Hide the FPS Counter\nF3 to Open User Folder\nF5 to Reset Scene"
	fps_text += "\n[color=PINK]Funkin' Raven[/color] v%s" % ProjectSettings.get_setting("application/config/version")
	fps_count.modulate = Color.RED if a_bad else Color.WHITE
	fps_count.text = fps_text

func show_tray() -> void:
	master_vol.show()
	var back_to: float = -30 - master_vol.size.y
	var sound: = preloader.get_resource("volume_%s" % ["appear" if master_vol.position.y == back_to else "change"])
	var sound_pitch: float = clampf(Settings.volume * 0.01, 0.3, 1.5)
	if master_vol.position.y == back_to:
		sound_pitch = 1.0

	SoundBoard.play_sfx(sound, sound_pitch, 0.4)
	master_vol.value = Settings.volume if not game_volume_muted else 0
	master_vol.position.y = 5

	if tray_twn != null: tray_twn.stop()
	tray_twn = create_tween().bind_node(master_vol).set_trans(Tween.TRANS_ELASTIC)
	tray_twn.tween_property(master_vol, "position:y", back_to, 1.0).set_delay(1)
	tray_twn.finished.connect(master_vol.hide)
