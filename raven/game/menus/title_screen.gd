extends Node2D

enum { TITLE_TEXT, TITLE_GF, TITLE_END }

@onready var sprites: Node2D = $sprites
@onready var text_group: Node2D = $text_group
@onready var gugo: Sprite2D = $godot_spr

@onready var logo_sprite: AnimatedSprite2D = $sprites/logo
@onready var enter_sprite: AnimatedSprite2D = $sprites/enter

# using the original state name here cuz yeah
static var title_state: int = TITLE_TEXT

var _selected: bool = false
var intro_blobs: Array[PackedStringArray] = []
var intro_display: PackedStringArray = ["my nuts", "itch"]

func reload_intro_text():
	if not ResourceLoader.exists("res://assets/data/introText.csv"): return
	var text: String = FileAccess.open("res://assets/data/introText.csv", FileAccess.READ).get_as_text()
	var split_text: PackedStringArray = text.dedent().split("\n")
	
	intro_blobs.clear()
	for i: int in split_text.size():
		if i == 0 or split_text[i].is_empty(): continue
		# cropping the text so we can properly translate
		var erase_index: int = clampi(split_text[i].find(","), 0, split_text[i].length())
		var eng_txt: String = split_text[i].erase(erase_index, split_text[i].length())
		var text_array: PackedStringArray = tr(eng_txt).split("--")
		if not text_array.is_empty() and text_array.size() > 1:
			intro_blobs.append(text_array)

func _ready():
	await RenderingServer.frame_post_draw
	Transition.rect.color = Color("#101010")
	RenderingServer.set_default_clear_color(Color.BLACK)
	enter_sprite.play("ENTER IDLE")
	Conductor.bpm = 102.0
	
	reload_intro_text()
	# this makes me dizzy.
	intro_display = intro_blobs[intro_blobs.find(intro_blobs.pick_random())]
	
	if not SoundBoard.bg_tracks.playing:
		SoundBoard.play_track(load("res://assets/audio/bgm/freakyMenu.ogg"), true, 0.01)
		create_tween().bind_node(SoundBoard.bg_tracks) \
		.tween_property(
			SoundBoard.bg_tracks, "volume_db",
			linear_to_db(0.7), 4
		)
		Conductor.active = true
		Conductor.time = 0.0
	
	if title_state == TITLE_END:
		sprites.visible = true
		title_state = TITLE_GF
		clear_text_blobs()

func _process(_delta: float):
	if Conductor.active and SoundBoard.bg_tracks.playing:
		Conductor.time = SoundBoard.bg_tracks.get_playback_position()

func _unhandled_key_input(e: InputEvent):
	if not e.pressed or _selected: return
	
	if e.is_action("ui_accept"):
		match title_state:
			TITLE_TEXT:
				screen_flash(0.8)
				clear_text_blobs()
				gugo.visible = false
				sprites.visible = true
				title_state = TITLE_GF
			TITLE_GF:
				screen_flash(0.8)
				_selected = true
				title_state = TITLE_END
				SoundBoard.play_sfx(Menu2D.CONFIRM_SOUND)
				
				if Settings.flashing_lights:
					enter_sprite.play("ENTER PRESSED")
				
				await get_tree().create_timer(0.8).timeout
				Tools.switch_scene(load("res://raven/game/menus/main_menu.tscn"))

func on_beat(beat: int):
	match title_state:
		TITLE_GF, TITLE_END:
			logo_sprite.frame = 0
			logo_sprite.play("logo bumpin")
		TITLE_TEXT:
			match beat:
				1: create_text_blob(["crowplexus", "srtpro278", "burgerballs9", "raltyro"])
				3: add_text_blob(tr("title_present"))
				4: clear_text_blobs()
				5: create_text_blob([tr("title_brazil")])
				7:
					add_text_blob(tr("title_godot"))
					gugo.visible = true
				8:
					clear_text_blobs()
					gugo.visible = false
				9: create_text_blob([intro_display[0]])
				11: add_text_blob(intro_display[1])
				12: clear_text_blobs()
				13: add_text_blob("Friday Night")
				14: add_text_blob("Funkin' Raven")
				15: add_text_blob(":3", 100)
				16:
					screen_flash()
					sprites.visible = true
					title_state = TITLE_GF
					clear_text_blobs()

func screen_flash(duration: float = 2, color: Color = Color.WHITE):
	$flash.modulate = color
	$flash.modulate.a = 1.0
	get_tree().create_tween() \
	.tween_property($flash, "modulate:a", 0.0, duration)

func create_text_blob(text: PackedStringArray, spacing: int = 60):
	for i in text.size():
		var new_group: Alphabet = Alphabet.new()
		new_group.alignment = 1
		new_group.text = text[i]
		new_group.position = Vector2(
			(get_viewport().size.x - new_group.size.x) * 0.5,
			(get_viewport().size.y - new_group.size.y) * 0.3
		)
		new_group.position.y += (i * spacing)
		text_group.add_child(new_group)

func add_text_blob(text: String, spacing: int = 60, color: Color = Color.WHITE):
	var new_text: Alphabet = Alphabet.new()
	new_text.alignment = 1
	new_text.text = text
	new_text.modulate = color
	new_text.position = Vector2(
		(get_viewport().size.x - new_text.size.x) * 0.5,
		(get_viewport().size.y - new_text.size.y) * 0.3
	)
	new_text.position.y += (text_group.get_child_count() * spacing)
	text_group.add_child(new_text)

func clear_text_blobs():
	for i: Alphabet in text_group.get_children():
		i.queue_free()
