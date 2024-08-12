extends Control

@export var skin: UISkin

var _judge_tween: Tween
var judgment_sprite: Sprite2D

var _template_combos: Array[Sprite2D] = []
var _combo_tweens: Array[Tween] = []

func push_judgement() -> void:
	judgment_sprite = Sprite2D.new()
	judgment_sprite.texture = skin.judgment_row
	judgment_sprite.texture_filter = skin.judgment_sprite_filter
	judgment_sprite.scale = skin.judgment_sprite_scale
	judgment_sprite.name = "judgement"
	judgment_sprite.modulate.a = 0.0
	judgment_sprite.vframes = 5
	add_child(judgment_sprite)

func push_combo(digits: int = 0) -> void:
	precache_number(digits)
	_combo_tweens.append(null)

func display_judgement(hit_result: Note.HitResult) -> void:
	if not judgment_sprite:
		push_judgement()

	judgment_sprite.frame = hit_result.judgment.frame - 1
	judgment_sprite.position = self.size * 0.5
	#judgment_sprite.modulate = hit_result.judgment.color
	judgment_sprite.modulate = Color.WHITE
	if Preferences.coloured_combo == 1 or Preferences.coloured_combo == 3:
		match Preferences.combo_colour_mode:
			0:
				if "color" in hit_result.judgment:
					judgment_sprite.modulate = hit_result.judgment.color
					judgment_sprite.modulate.v = 1.2
			1:
				var cf: String = Scoring.get_clear_flag(hit_result.player.tallies.hit_registry)
				if hit_result.player.tallies.breaks > 0: cf = "SDCB"
				judgment_sprite.modulate = Scoring.get_clear_flag_color(cf)
	judgment_sprite.position.y -= 80
	judgment_sprite.scale *= 1.1

	if _judge_tween:
		_judge_tween.stop()

	_judge_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	_judge_tween.tween_property(judgment_sprite, "scale", skin.judgment_sprite_scale, 0.35 * Conductor.crotchet).set_ease(Tween.EASE_IN)
	_judge_tween.tween_property(judgment_sprite, "position:y", judgment_sprite.position.y + 10, 0.35 * Conductor.crotchet).set_ease(Tween.EASE_IN)
	_judge_tween.tween_property(judgment_sprite, "modulate:a", 0.0, 0.8 * Conductor.crotchet) \
	.set_ease(Tween.EASE_IN_OUT).set_delay(0.6 * Conductor.crotchet)

func display_combo(hit_result: Note.HitResult) -> void:
	var count: int = hit_result.player.tallies.combo
	var konbo_janai: bool = sign(count) == -1
	var combo_colour: Color = Color.WHITE
	if not konbo_janai:
		if Preferences.coloured_combo == 2 or Preferences.coloured_combo == 3:
			match Preferences.combo_colour_mode:
				0:
					if "color" in hit_result.judgment:
						combo_colour = hit_result.judgment.color
						combo_colour.v = 1.2
				1:
					if hit_result.player.tallies.breaks < 10:
						var cf: String = Scoring.get_clear_flag(hit_result.player.tallies.hit_registry)
						if hit_result.player.tallies.breaks > 0: cf = "SDCB"
						combo_colour = Scoring.get_clear_flag_color(cf)
	else:
		combo_colour = Color.CRIMSON

	var _str_combo: String = str(count).pad_zeros(2)
	var offsetx: float = _str_combo.length() - 3

	for i: int in _str_combo.length():
		if _template_combos.size() < _str_combo.length():
			push_combo(_str_combo.length())

		var num_score: Sprite2D = _template_combos[i]
		num_score.position = self.size * 0.5
		num_score.position.x += 40 * (i - offsetx)
		num_score.modulate = combo_colour
		if Preferences.always_display_combo and _template_combos.size() > _str_combo.length():
			for ns: CanvasItem in _template_combos:
				if ns.get_index() > _str_combo.length():
					ns.modulate.a = 0.0
		num_score.scale *= 1.2

		var frame: int = _str_combo[i].to_int() + 1
		if konbo_janai and i == 0:
			frame = 0

		num_score.frame = frame

		if _combo_tweens[i]:
			_combo_tweens[i].kill()
		_combo_tweens[i] = create_tween().set_ease(Tween.EASE_IN_OUT).set_parallel(true)
		_combo_tweens[i].tween_property(num_score, "scale", skin.combo_num_sprite_scale, 0.4 * Conductor.crotchet)
		if not Preferences.always_display_combo:
			_combo_tweens[i].tween_property(num_score, "modulate:a", 0.0, 1.2 * Conductor.crotchet) \
			.set_delay(0.6 * Conductor.crotchet)

func precache_number(i: int) -> Sprite2D:
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
