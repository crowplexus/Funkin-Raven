extends Control

@export var skin: UISkin

var judge_tween: Tween
var number_tweens: Array[Tween] = []
var combo_tween: Tween

func prepare() -> void:
	display_judgement(0, true)
	display_combo_sprite(true)
	display_combo(0, true)

func display_judgement(judge_id: int, precache: bool = false) -> void:
	if not has_node("judgement"):
		var judgement: Sprite2D = skin.create_judgement_spr()
		judgement.position = Vector2(self.size.x * 0.5, -10)
		judgement.name = "judgement"
		judgement.hide()
		add_child(judgement)
		if precache: return

	if judge_tween != null: judge_tween.kill()

	var judgement: Sprite2D = get_node("judgement")
	judgement.frame = judge_id
	judgement.modulate.a = 1.0
	judgement.scale = skin.judgement_scale
	judgement.show()

	# ANIMATION #

	judgement.scale *= 1.25

	judge_tween = create_tween().bind_node(judgement)
	judge_tween.set_parallel(true)

	judge_tween.tween_property(judgement, "position:y", 0, 0.35).set_trans(Tween.TRANS_SINE)
	judge_tween.tween_property(judgement, "scale", skin.judgement_scale, 0.15).set_trans(Tween.TRANS_BOUNCE)

	judge_tween.tween_property(judgement, "modulate:a", 0.0, 0.3) \
	.set_ease(Tween.EASE_OUT).set_delay(0.105 * Conductor.crotchet_mult)
	judge_tween.finished.connect(judgement.hide)

func display_combo(combo: int, precache: bool = false) -> void:
	var combo_str: PackedStringArray = str(combo).pad_zeros(2).split("")

	for i: int in combo_str.size():
		if not has_node("number_%s" % i):
			make_combo_number(i)
			number_tweens.append(null)
			if precache: return

		var number: Sprite2D = get_node("number_%s" % i)
		number.position = Vector2((self.size.x * 0.5), 90)
		number.position.x += (55 * (i - combo_str.size() - 3) + 150)
		number.scale = skin.numbers_scale
		number.frame = int(combo_str[i])
		number.modulate.a = 1.0
		number.show()

		# ANIMATION #
		number.scale *= 1.15

		if number_tweens[i] != null: number_tweens[i].kill()

		number_tweens[i] = create_tween().bind_node(number)
		number_tweens[i].set_parallel(true)

		number_tweens[i].tween_property(number, "scale", skin.numbers_scale, 0.3).set_ease(Tween.EASE_IN)
		number_tweens[i].tween_property(number, "modulate:a", 0.0, 0.6) \
		.set_ease(Tween.EASE_OUT).set_delay(0.1 * Conductor.crotchet_mult)
		number_tweens[i].finished.connect(number.hide)

	if combo % 5 == 0:
		display_combo_sprite()

func display_combo_sprite(precache: bool = false) -> void:
	if not has_node("combo"):
		var combo_spr: Sprite2D = skin.create_combo_spr()
		combo_spr.name = "combo"
		combo_spr.hide()
		add_child(combo_spr)
		if precache: return

	if combo_tween != null: combo_tween.kill()
	var combo_spr: Sprite2D = get_node("combo")

	combo_spr.position = Vector2((self.size.x * 0.5) + 70, 90)
	combo_spr.scale = skin.combo_scale
	combo_spr.modulate.a = 1.0
	combo_spr.show()
	# ANIMATION #
	combo_spr.scale *= 1.15

	combo_tween = create_tween().bind_node(combo_spr)
	combo_tween.set_parallel(true)

	combo_tween.tween_property(combo_spr, "scale", skin.combo_scale, 0.3)

	combo_tween.tween_property(combo_spr, "modulate:a", 0.0, 0.3) \
	.set_ease(Tween.EASE_OUT).set_delay(0.105 * Conductor.crotchet_mult)
	combo_tween.finished.connect(combo_spr.hide)

func make_combo_number(digit: int) -> void:
	var number: Sprite2D = skin.create_combo_number()
	number.name = "number_%s" % digit
	number.hide()
	add_child(number)
