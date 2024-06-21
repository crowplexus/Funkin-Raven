extends Node2D

@onready var sprites: Node2D = $"sprites"
@onready var logo_animation: AnimationPlayer = $"sprites/logo/animation_player"
@onready var enter_sprite: AnimatedSprite2D = $"sprites/enter_sprite"

var _enter_animation_backwards: bool = false
var _enter_animation: Callable = func() -> void:
	if enter_sprite.animation.ends_with("IDLE"):
		if _enter_animation_backwards:
			enter_sprite.play("ENTER IDLE")
		else:
			enter_sprite.play_backwards("ENTER IDLE")
		_enter_animation_backwards = not _enter_animation_backwards

var _intro_skipped: bool = false
var _transitioning: bool = false


func _ready() -> void:
	Conductor.active = false
	RenderingServer.set_default_clear_color(Color.BLACK)
	await RenderingServer.frame_post_draw

	enter_sprite.play("ENTER IDLE")
	enter_sprite.animation_finished.connect(_enter_animation)

	Conductor.bpm = Globals.MENU_MUSIC_BPM
	Conductor.ibeat_reached.connect(on_ibeat_reached)

	if not SoundBoard.is_bgm_playing():
		SoundBoard.play_bgm(Globals.MENU_MUSIC, 0.01)
		SoundBoard.fade_bgm(0.01, 0.7, 4.0)
		Conductor.active = true


func _process(_delta: float) -> void:
	if SoundBoard.is_bgm_playing():
		Conductor.time = SoundBoard.bgm_player.get_playback_position() + AudioServer.get_time_since_last_mix()


func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if not _intro_skipped:
			skip_intro(Color.WHITE, 1.0 if Preferences.flashing else 0.0)
		elif not _transitioning:
			if Preferences.flashing:
				enter_sprite.play("ENTER PRESSED")
			SoundBoard.play_sfx(Globals.MENU_CONFIRM_SFX)
			_transitioning = true
			await get_tree().create_timer(1.0).timeout
			Globals.change_scene(load("res://scenes/menu/main_menu.tscn"))


func _exit_tree() -> void:
	if Conductor.ibeat_reached.is_connected(on_ibeat_reached):
		Conductor.ibeat_reached.disconnect(on_ibeat_reached)


func on_ibeat_reached(ibeat: int) -> void:
	if ibeat % 2 == 0:
		logo_animation.seek(0.0)
		logo_animation.play("bump")

	if _intro_skipped == true:
		return

	match ibeat:
		16: skip_intro(Color.WHITE, 1.0 if Preferences.flashing else 0.0)


func skip_intro(flash_colour: Color = Color.WHITE, flash_duration: float = 4.0) -> void:
	_intro_skipped = true

	if flash_duration > 0.0:
		$"flash".modulate = flash_colour
		create_tween().set_ease(Tween.EASE_OUT).bind_node($"flash") \
		.tween_property($"flash", "modulate:a", 0.0, flash_duration)

	sprites.visible = true
