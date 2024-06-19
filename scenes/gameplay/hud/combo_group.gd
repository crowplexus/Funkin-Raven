extends Control

@export var skin: UISkin

var judgment_sprite: Sprite2D

var _judge_tween: Tween
var _combo_tweens: Array[Tween] = []
var _template_combos: Array[Sprite2D] = []


func _ready() -> void:
	judgment_sprite = Sprite2D.new()
	judgment_sprite.texture = skin.judgment_row
	judgment_sprite.texture_filter = skin.judgment_sprite_filter
	judgment_sprite.scale = skin.judgment_sprite_scale
	judgment_sprite.name = "judgement"
	judgment_sprite.modulate.a = 0.0
	judgment_sprite.vframes = 5
	add_child(judgment_sprite)

	# PRECACHE COMBO #

	_combo_tweens = []
	#for id: int in 3:
	#	_template_combos.append(precache_combo_number(id))
	#	_combo_tweens.append(null)
	#add_child(_template_combo)


func recreate_popup_tween() -> Tween:
	var e: Tween = create_tween().bind_node(judgment_sprite)
	e.set_ease(Tween.EASE_IN_OUT)
	e.set_parallel(true)
	return e


func pop_up_judge(hit_result: Note.HitResult, is_tap: bool) -> void:
	if not is_tap:
		return

	judgment_sprite.frame = Scoring.JUDGMENTS.find(hit_result.judgment)
	judgment_sprite.position = get_viewport_rect().size * 0.5
	#judgment_sprite.modulate = hit_result.judgment.color
	judgment_sprite.modulate.a = 1.0
	judgment_sprite.position.y -= 80
	judgment_sprite.scale *= 1.1

	if is_instance_valid(_judge_tween):
		_judge_tween.stop()

	_judge_tween = recreate_popup_tween()
	_judge_tween.tween_property(judgment_sprite, "scale", skin.judgment_sprite_scale, 0.35 * Conductor.crotchet).set_ease(Tween.EASE_IN)
	_judge_tween.tween_property(judgment_sprite, "position:y", judgment_sprite.position.y + 10, 0.35 * Conductor.crotchet).set_ease(Tween.EASE_IN)
	_judge_tween.tween_property(judgment_sprite, "modulate:a", 0.0, 0.8 * Conductor.crotchet) \
	.set_ease(Tween.EASE_IN_OUT).set_delay(0.6 * Conductor.crotchet)


func pop_up_combo(hit_result: Note.HitResult, is_tap: bool) -> void:
	if not is_tap:
		return

	var count: int = hit_result.player.combo

	var konbo_janai: bool = sign(count) == -1
	var combo_colour: Color = Color.WHITE
	var _str_combo: String = str(count).pad_zeros(2)
	var offsetx: float = _str_combo.length() - 3
	if konbo_janai: combo_colour = Color.RED

	for i: int in _str_combo.length():
		if _template_combos.size() < _str_combo.length():
			precache_combo_number(_str_combo.length())
			_combo_tweens.append(null)

		var num_score: = _template_combos[i]
		num_score.position = get_viewport_rect().size * 0.5
		num_score.position.x += 45 * (i - offsetx)
		num_score.modulate = combo_colour
		num_score.scale *= 1.2

		var frame: int = _str_combo[i].to_int() + 1
		if konbo_janai and i == 0:
			frame = 0

		num_score.frame = frame

		if is_instance_valid(_combo_tweens[i]):
			_combo_tweens[i].kill()

		_combo_tweens[i] = recreate_popup_tween()
		_combo_tweens[i].tween_property(num_score, "scale", skin.combo_num_sprite_scale, 0.4 * Conductor.crotchet)
		_combo_tweens[i].tween_property(num_score, "modulate:a", 0.0, 1.2 * Conductor.crotchet) \
		.set_delay(0.6 * Conductor.crotchet)


func show_combo_temporary(hit_result: Note.HitResult, is_tap: bool) -> void:
	if not is_tap or hit_result.judgment == null or hit_result.judgment.is_empty():
		return

	var hit_colour: Color = Color.DIM_GRAY
	if "color" in hit_result.judgment:
		hit_colour = hit_result.judgment.color
	elif "colour" in hit_result.judgment: # british.
		hit_colour = hit_result.judgment.colour

	#hit_result_label.text = (str(hit_result.judgment.name) +
	#	"\nTiming: %sms" % snappedf(hit_result.hit_time, 0.001) +
	#	"\nCombo: %s" % hit_result.player.combo)
	#hit_result_label.modulate = hit_colour
#
	#if is_instance_valid(combo_tween):
	#	combo_tween.kill()

	#combo_tween = create_tween().set_ease(Tween.EASE_OUT)
	#combo_tween.bind_node(hit_result_label)
	#combo_tween.tween_property(hit_result_label, "modulate:a", 0.0, 0.5 * Conductor.crotchet) \
	#.set_delay(0.5 * Conductor.crotchet)


func precache_combo_number(i: int) -> Sprite2D:
	# i was upset fuck naming
	var _combo_shit: = Sprite2D.new()
	_combo_shit.texture = skin.combo_row
	_combo_shit.texture_filter = skin.combo_num_sprite_filter
	_combo_shit.scale = skin.combo_num_sprite_scale
	_combo_shit.name = "combo_%s" % i
	_combo_shit.modulate.a = 0.0
	_combo_shit.hframes = 11
	_combo_shit.frame = 1
	add_child(_combo_shit)
	_template_combos.append(_combo_shit)
	return _combo_shit
