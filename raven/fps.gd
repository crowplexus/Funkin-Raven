extends CanvasLayer

const VOLUME_SFX: = preload("res://assets/audio/sfx/menu/scrollMenu.ogg")

@onready var texts: Control = $text_control
@onready var fps_count: RichTextLabel = $text_control/fps_count
@onready var master_vol: ProgressBar = $volume_tray

var tray_twn: Tween

func _ready():
	var bonk: Timer = Timer.new()
	add_child(bonk)
	
	update_stats()
	bonk.start(1.0)
	bonk.timeout.connect(func():
		update_stats()
		bonk.start(1.0)
	)
	master_vol.modulate.a = 0.0
	master_vol.value = Settings.volume

func _unhandled_key_input(e: InputEvent):
	# debug shit temporary
	var axis: int = int(Input.get_axis("volume_down", "volume_up"))
	if axis != 0:
		if master_vol.modulate.a != 0.0:
			Settings.volume += 5 * axis
		show_tray()
	
	if e.pressed: match e.keycode:
		KEY_F1: texts.visible = not texts.visible
		KEY_F5:
			SoundBoard.stop_tracks()
			SoundBoard.stop_sounds()
			if PlayField.play_manager != null:
				PlayField.play_manager.reset()
			await RenderingServer.frame_post_draw
			get_tree().paused = false
			Tools.refresh_scene(true)

var pram: int = 0
func update_stats():
	var fps: float = Engine.get_frames_per_second()
	var fps_text: String = "%s FPS" %  fps
	var a_bad: bool = Settings.framerate_mode != 1 and fps <= Engine.max_fps * 0.5
	
	if OS.is_debug_build():
		var ram: = OS.get_static_memory_usage()
		if ram > pram: pram = ram
		fps_text += " | " + "%s / [color=GRAY]%s[/color]" % [
			String.humanize_size( int(ram)), String.humanize_size( int(pram) )]
		a_bad = a_bad or ram <= (ram * 0.5)
	fps_text += "\n[color=PINK]Funkin' Raven[/color] v%s" % ProjectSettings.get_setting("application/config/version")
	fps_count.modulate = Color.RED if a_bad else Color.WHITE
	fps_count.text = fps_text

func show_tray():
	master_vol.value = Settings.volume
	master_vol.modulate.a = 1.0
	SoundBoard.play_sfx(VOLUME_SFX, randf_range(0.5, 1.5))
	if tray_twn != null: tray_twn.stop()
	tray_twn = create_tween().set_ease(Tween.EASE_OUT)
	tray_twn.tween_property(master_vol, "modulate:a", 0.0, 0.5).set_delay(1.0)
