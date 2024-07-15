extends Node2D

@onready var sprites: Node2D = $"sprites"
@onready var crow_sprite: Sprite2D = $"crow"
@onready var logo_animation: AnimationPlayer = $"sprites/logo/animation_player"
@onready var enter_sprite: AnimatedSprite2D = $"sprites/enter_sprite"
@onready var thingy: Alphabet = $"text_thingy"

var spam_counter: int = 0

var _enter_animation_backwards: bool = false
var _enter_animation: Callable = func() -> void:
	if enter_sprite.animation.ends_with("IDLE"):
		if _enter_animation_backwards:
			enter_sprite.play("ENTER IDLE")
		else:
			enter_sprite.play_backwards("ENTER IDLE")
		_enter_animation_backwards = not _enter_animation_backwards

var _intro_skipped: bool = false
# i was gonna do a resource but ehhh
# pretty much everyone is just gonna replace this when modding anyway
var _intro_texts: Array = [
	["fnf", "but woke"],
	#["swagshit", "moneymoney"],
	["shoutouts to", "psych engine"],
	["love and hugs", "from brazil"],
	["why godot?", "why not!"],
]
var _cur_rando: PackedStringArray = ["swagshit", "moneymoney"]


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	await RenderingServer.frame_post_draw

	_cur_rando = _intro_texts.pick_random()

	thingy.text = ""
	thingy.visible = true

	enter_sprite.play("ENTER IDLE")
	enter_sprite.animation_finished.connect(_enter_animation)

	Conductor.bpm = Globals.MENU_MUSIC_BPM
	Conductor.ibeat_reached.connect(on_ibeat_reached)

	if not SoundBoard.is_bgm_playing():
		SoundBoard.play_bgm(Globals.MENU_MUSIC, 0.01)
		SoundBoard.fade_bgm(0.01, 0.7, 4.0)


func _process(_delta: float) -> void:
	if SoundBoard.is_bgm_playing():
		Conductor.update(SoundBoard.get_bgm_pos() + AudioServer.get_time_since_last_mix())


func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if not _intro_skipped:
			skip_intro(Color.WHITE, 1.0 if Preferences.flashing else 0.0)
		else:
			Globals.set_node_inputs(self, false)
			if Preferences.flashing:
				enter_sprite.play("ENTER PRESSED")
			SoundBoard.play_sfx(Globals.MENU_CONFIRM_SFX)
			await get_tree().create_timer(0.8).timeout
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
		1: thingy.text = "a Game by\n"
		3: thingy.text += "the Funkin' Crew Inc."
		4: thingy.text = ""
		5: thingy.text = "a Fan-remake..."
		7:
			thingy.text += "\nby crowplexus"
			crow_sprite.visible = true
		8:
			thingy.text = ""
			crow_sprite.visible = false
		9: thingy.text = _cur_rando[0]
		11:
			thingy.text += "\n" + _cur_rando[1]
			if thingy.text.to_lower().contains("psych"):
				SoundBoard.play_sfx(load("res://assets/audio/sfx/psych.ogg"))
		12: thingy.text = ""
		13: thingy.text = "Friday"
		14: thingy.text += "\nNight"
		15: thingy.text += "\nFunkin'"
		16: skip_intro(Color.WHITE, 1.0 if Preferences.flashing else 0.0)


func skip_intro(flash_colour: Color = Color.WHITE, flash_duration: float = 4.0) -> void:
	_intro_skipped = true
	crow_sprite.visible = false
	thingy.visible = false
	thingy.text = ""

	if flash_duration > 0.0:
		$"flash".modulate = flash_colour
		create_tween().set_ease(Tween.EASE_OUT).bind_node($"flash") \
		.tween_property($"flash", "modulate:a", 0.0, flash_duration)
	sprites.visible = true
