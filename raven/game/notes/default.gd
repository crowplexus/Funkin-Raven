extends Note

func _ready():
	arrow = $"arrow"
	if arrow == null:
		push_warning("This note has no arrow node, making it impossible to be spawned ", data._to_string())
		queue_free()
		return
	
	do_follow = receptor != null
	position = Vector2(INF, -INF)
	
	arrow.play(anim_prefix)
	if receptor != null: arrow.rotate(receptor.rotation)
	if is_sustain or debug:
		og_len = data.s_len
		make_sustain()

func make_sustain():
	clip_rect = Control.new()
	clip_rect.clip_contents = true
	add_child(clip_rect)
	move_child(clip_rect, 0)

	var tail: = TextureRect.new()
	tail.texture = sustain_frames.get_frame_texture(anim_prefix + " hold end", 0)
	tail.layout_mode = 1
	tail.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tail.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tail.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var hold: = TextureRect.new()
	hold.texture = sustain_frames.get_frame_texture(anim_prefix + " hold piece", 0)
	hold.layout_mode = 1
	hold.set_anchors_preset(Control.PRESET_FULL_RECT)
	hold.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -tail.texture.get_height() + 1.0)
	hold.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hold.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	clip_rect.size.x = maxf(tail.texture.get_width(), hold.texture.get_width())
	clip_rect.position.x -= clip_rect.size.x * 0.5
	clip_rect.add_child(hold)
	clip_rect.add_child(tail)
	
	clip_rect.scale.y = scroll
	clip_rect.modulate.a = 0.6
	# clip behind receptors
	clip_rect.z_index = -1 if not $"../../".debug else 1

func splash():
	if not has_node("splash"): return
	var firework: = $splash.duplicate() as AnimatedSprite2D
	if not $splash.has_node("anim"): return
	#firework.global_position = self.global_position
	firework.visible = true
	receptor.add_child(firework)
	
	var _thing: = firework.get_node("anim") as AnimationPlayer
	_thing.play("splash %s" % [ NoteData.color_to_str(data.dir) + " " + str(randi_range(1, 2)) ])
	_thing.animation_finished.connect(func(_anim: StringName): firework.queue_free())
