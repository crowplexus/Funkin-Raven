extends Control

@export var skin: UISkin
## Max Amount of Sprites that can be spawned
@export var max_sprites: int = 30

func display_judgement(le_judge: String):
	if get_child_count() > max_sprites: clear_screen()
	var judgement: VelocitySprite2D = skin.create_judgement_spr(le_judge)
	judgement.name = "judgement %s" % le_judge.to_snake_case()
	judgement.position = Vector2(self.size.x * 0.5, 0)
	
	judgement.acceleration = Vector2(0, randi_range(480, 530))
	judgement.velocity -= Vector2(randi_range(0, 10), randi_range(140, 175))
	
	add_child(judgement)
	
	#var inc: Vector2 = Vector2(0.1, 0.1)
	#if skin.resource_name == "pixel":
	#	inc = Vector2.ONE
	#judgement.scale += inc
	
	# [ SCALE BUMP ] #
	#get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE) \
	#.tween_property(judgement, "scale", skin.judgement_scale, 0.15)
	
	# [ FADE OUT ] #
	create_tween().set_ease(Tween.EASE_OUT).bind_node(judgement) \
	.tween_property(judgement, "modulate:a", 0.0, 0.3) \
	.set_delay(0.105 * Conductor.beat_mult) \
	.finished.connect(judgement.queue_free)

func display_combo(combo: int):
	var combo_str: PackedStringArray = str(combo).pad_zeros(2).split("")
	
	for i in combo_str.size():
		var yeah: int = int(combo_str[i])
		var number: VelocitySprite2D = skin.create_combo_number(yeah)
		number.name = "number%s" % i
		number.position = Vector2((self.size.x * 0.5), 90)
		number.position.x += (55 * (i - combo_str.size() - 3) + 150)
		
		number.acceleration = Vector2(0, randi_range(530, 600))
		number.velocity -= Vector2(randi_range(1, 10), randi_range(150, 250))
		
		add_child(number)
		
		# [ FADE OUT ] #
		create_tween().set_ease(Tween.EASE_OUT).bind_node(number) \
		.tween_property(number, "modulate:a", 0.0, 0.6) \
		.set_delay(0.1 * Conductor.beat_mult) \
		.finished.connect(number.queue_free)
	
	if skin.combo != null:
		var combo_spr: VelocitySprite2D = skin.create_combo_spr()
		combo_spr.position = Vector2((self.size.x * 0.5) + 70, 90)
		combo_spr.name = "combo"
		
		combo_spr.acceleration = Vector2(0, randi_range(480, 530))
		combo_spr.velocity -= Vector2(randi_range(0, 10), randi_range(140, 175))
		add_child(combo_spr)
		
		create_tween().set_ease(Tween.EASE_OUT).bind_node(combo_spr) \
		.tween_property(combo_spr, "modulate:a", 0.0, 0.3) \
		.set_delay(0.105 * Conductor.beat_mult) \
		.finished.connect(combo_spr.queue_free)

func clear_screen():
	for i: Sprite2D in get_children():
		i.queue_free()
