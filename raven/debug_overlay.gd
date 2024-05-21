extends CanvasLayer

@onready var perf_text: RichTextLabel = $"performance_text"
@onready var master_vol: ProgressBar = $"volume_tray"
@onready var preloader: ResourcePreloader = $"preloader"

var tray_twn: Tween
var game_volume_muted: bool = false
var show_debug_keys: bool = false
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
		KEY_F2:
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))
		KEY_F3:
			if perf_text.visible:
				show_debug_keys = not show_debug_keys
				update_stats()
			if not show_debug_keys:
				perf_text.visible = not perf_text.visible
		KEY_F5:
			if OS.is_debug_build():
				SoundBoard.stop_tracks()
				SoundBoard.stop_sounds()
				if PlayField.play_manager != null:
					PlayField.play_manager.reset()
				await RenderingServer.frame_post_draw
				get_tree().paused = false
				Tools.refresh_scene(true)

func update_stats() -> void:
	if not perf_text.visible:
		return

	perf_text.text = "[font_size=18]%s[/font_size] FPS" % Engine.get_frames_per_second()

	if OS.is_debug_build():
		var ram: = OS.get_static_memory_usage()
		if ram > pram: pram = ram
		var a_bad: bool = ram <= ram * 0.5
		var color_name: StringName = "GRAY"
		if a_bad: color_name = "RED"
		perf_text.text += "\n%s RAM\n[color=%s]%s[/color] PEAK" % [
			String.humanize_size(int(ram)), color_name,
			String.humanize_size(int(pram))]

	if show_debug_keys:
		perf_text.text += "\n\nF2 to Open User Folder"
		perf_text.text += "\nF3 to Hide Keybinds, again for this entire text"
		if OS.is_debug_build():
			perf_text.text += "\nF5 to Reset Scene"
		perf_text.text += "\n"

	perf_text.text += "\n[font_size=12]Funkin' Raven [color=PINK]v%s[/color][/font_size]" % [
		ProjectSettings.get_setting("application/config/version")]

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
