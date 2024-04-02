extends Node2D

@onready var letters: Control = $"letters"
@onready var notefield: NoteField = $"notefield"
@onready var question: Alphabet = $"question"

var can_change: bool = false

var current_question: int = 0
var selectors: Array[String] = []
var selected: int = 0

var questions: Dictionary = {
	"language": "setup_language",
	"flashing_lights": "setup_flashing_lights",
	"scroll": "setup_scroll"
}

var answers: Array = [
	["English", "Português", "Español"],
	["setup_answer_no", "setup_answer_yes"],
	["setup_answer_up","setup_answer_down","setup_answer_split_ud","setup_answer_split_du",]
]

func _ready():
	$bg.modulate.a = 0.0
	question.modulate.a = 0.0
	
	await RenderingServer.frame_post_draw
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	Settings._is_cfg_loaded()
	if not Settings._cfg.has_section_key("System", "setup_ended"):
		Settings._cfg.set_value("System", "setup_ended", false)
	
	if Settings._cfg.get_value("System", "setup_ended", false) == true:
		Tools.switch_scene(load("res://raven/game/menus/title_screen.tscn"), true)
		return
	
	create_tween().set_ease(Tween.EASE_IN) \
	.tween_property($bg, "modulate:a", 0.6, 0.8)
	
	#print_debug(Settings._cfg.encode_to_text())
	display_question()

func display_text(tag: String, text: String, off: Vector2 = Vector2.ZERO, scal: Vector2 = Vector2.ONE):
	var alpha: Alphabet = question.duplicate()
	alpha.name = tag
	alpha.scale = scal
	alpha.modulate.a = 0.0
	alpha.text = text
	
	alpha.position = Vector2(
		(get_viewport().size.x - alpha.size.x) * 0.25,
		(get_viewport().size.y - alpha.size.y) * 0.3
	)
	
	alpha.position += off
	letters.add_child(alpha)

func _unhandled_key_input(_e: InputEvent):
	if not can_change: return
	
	var lr: int = int( Input.get_axis("ui_up", "ui_down") )
	if lr != 0: update_selection(lr)
	
	if Input.is_action_just_pressed("ui_accept"):
		match current_question:
			0: # Language
				Settings.language = selected
			1: # Flashing Lights
				Settings.flashing_lights = selected == 1
			2:
				Settings.scroll = selected
		
		if current_question < questions.keys().size() - 1:
			display_question(1)
		else:
			reset_question()
			notefield.transition(0.3, true)
			Settings._cfg.set_value("System", "setup_ended", true)
			Settings.save_settings()
			
			await get_tree().create_timer(0.8).timeout
			
			display_text("end1", tr("setup_end1"),	Vector2(0, 0), Vector2(0.9, 0.9) )
			display_text("end2", tr("setup_end2"),	Vector2(0, 80), Vector2(0.9, 0.9) )
			display_text("end3", tr("setup_end3"),	Vector2(0, 150), Vector2(0.9, 0.9) )
			display_text("end5", "-crowplexus",		Vector2(0, 350), Vector2(0.9, 0.9) )
			
			for i: int in letters.get_child_count():
				letters.get_child(i).position.x += 100
				var twn: Tween = create_tween().bind_node(letters.get_child(i))
				twn.tween_property(letters.get_child(i), "modulate:a", 1.0, i * 0.5)
			
			await get_tree().create_timer(6.0).timeout
			Tools.switch_scene(load("res://raven/game/menus/title_screen.tscn"))

func update_selection(value: int = 0):
	if answers[current_question].size() == 0: return
	
	if value != 0:
		SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	
	selected = wrapi(selected + value, 0, answers[current_question].size())
	match questions.keys()[current_question]:
		"language":
			if can_change:
				TranslationServer.set_locale( Settings._LANGS.keys()[selected].to_lower() )
				question.text = tr("setup_language")
				question.update_alignment(question.alignment)
		"scroll":
			if notefield.visible:
				notefield.set_scroll(selected, true)
	
	for i: int in answers[current_question].size():
		letters.get_node(answers[current_question][i]).modulate.a = 0.6 if i != selected else 1.0

func display_question(next: int = 0):
	reset_question()
	await get_tree().create_timer(0.5).timeout
	
	current_question = clampi(current_question + next, 0, questions.keys().size())
	
	match current_question:
		2:
			notefield.transition(0.5)
			notefield.visible = true
	
	var key: String = questions.keys()[current_question]
	question.text = tr(questions[key])
	question.update_alignment(question.alignment)
	
	create_tween().bind_node(question) \
	.tween_property(question, "modulate:a", 1.0, 0.4)
	
	for i: int in answers[current_question].size():
		var answer: String = answers[current_question][i]
		var offset: Vector2 = Vector2(0, 180 + (100 * i) )
		display_text(answer, tr(answer), offset)
		
		var tweener: Tween = get_tree().create_tween().bind_node(letters.get_node(answer))
		tweener.tween_property(letters.get_node(answer), "modulate:a", 0.6, 0.6) \
		.set_delay(0.7 * i)
		
		if i >= answers[current_question].size() - 1:
			tweener.finished.connect(func():
				can_change = true
				update_selection()
			)

func clear_text(tween: bool = true):
	for letter: Alphabet in letters.get_children():
		if not tween: letter.free()
		else:
			get_tree().create_tween() \
			.tween_property(letter, "modulate:a", 0.0, 0.6) \
			.finished.connect(letter.queue_free)

func reset_question():
	get_tree().create_tween() \
	.tween_property(question, "modulate:a", 0.0, 0.6)
	can_change = false
	selected = 0
	clear_text()
