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
	["setup_answer_yes", "setup_answer_no"],
	["setup_answer_up","setup_answer_down","setup_answer_split_ud","setup_answer_split_du",]
]

func _ready() -> void:
	$bg.modulate.a = 0.0
	question.modulate.a = 0.0

	await RenderingServer.frame_post_draw
	RenderingServer.set_default_clear_color(Color.BLACK)

	Settings._is_cfg_loaded()
	if not Settings._cfg.has_section_key("System", "setup_ended"):
		Settings._cfg.set_value("System", "setup_ended", false)

	if Settings._cfg.get_value("System", "setup_ended", false) == true:
		Tools.switch_scene(load("res://raven/menu/title_screen.tscn"), true)
		return

	create_tween().set_ease(Tween.EASE_IN) \
	.tween_property($bg, "modulate:a", 0.6, 0.8)
	display_question()

func display_text(tag: String, text: String, off: Vector2 = Vector2.ZERO, scal: Vector2 = Vector2.ONE)  -> void:
	var alpha: Alphabet = question.duplicate() as Alphabet
	alpha.name = tag
	alpha.modulate.a = 0.0
	alpha.text = text
	alpha.scale = scal
	alpha.alignment = 1
	alpha.position += off
	letters.add_child(alpha)

func _unhandled_key_input(_e: InputEvent) -> void:
	if not can_change: return

	var lr: int = int( Input.get_axis("ui_up", "ui_down") )
	if lr != 0: update_selection(lr)

	if Input.is_action_just_pressed("ui_accept"):
		match current_question:
			0: # Language
				Settings.language = selected
			1: # Flashing Lights
				Settings.flashing_lights = selected == 1
			2: # Note Scroll Direction
				Settings.scroll = selected

		if current_question < questions.keys().size() - 1:
			display_question(1)
		else:
			reset_question()
			notefield.transition(0.3, true)

			await get_tree().create_timer(1.0).timeout

			Settings._cfg.load(Settings._CONFIG_PATH)
			Settings._cfg.set_value("System", "setup_ended", true)
			Settings._cfg.save(Settings._CONFIG_PATH)

			Tools.switch_scene(load("res://raven/menu/title_screen.tscn"))

func update_selection(value: int = 0) -> void:
	if answers[current_question].size() == 0: return

	if value != 0:
		SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)

	selected = wrapi(selected + value, 0, answers[current_question].size())
	match questions.keys()[current_question]:
		"language":
			if can_change:
				TranslationServer.set_locale( Settings._LANGS.keys()[selected] )
				await RenderingServer.frame_post_draw
				question.text = tr("setup_language")
				question.update_alignment(question.alignment)
		"scroll":
			if notefield.visible:
				notefield.set_scroll(selected, true)

	for i: int in answers[current_question].size():
		letters.get_node(answers[current_question][i]).modulate.a = 0.4 if i != selected else 1.0

func display_question(next: int = 0) -> void:
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
			tweener.finished.connect(func() -> void:
				can_change = true
				update_selection()
			)

func clear_text(tween: bool = true) -> void:
	for letter: Alphabet in letters.get_children():
		if not tween: letter.free()
		else:
			get_tree().create_tween() \
			.tween_property(letter, "modulate:a", 0.0, 0.6) \
			.finished.connect(letter.queue_free)

func reset_question() -> void:
	get_tree().create_tween() \
	.tween_property(question, "modulate:a", 0.0, 0.6)
	can_change = false
	selected = 0
	clear_text()
