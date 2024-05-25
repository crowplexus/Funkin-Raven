extends Note

func assign_arrow() -> void:
	if is_instance_valid(receptor) and receptor.skin.propagate_call("assign_arrow", [self]) == 0:
		return

	arrow = $"arrow"
	arrow.modulate = Color(Chart.NoteData.color_to_str(data.column).to_upper())
	arrow.modulate.v = 1.5 # make it clear that its a tap note.

func _ready() -> void:
	super()
	assign_arrow()

	if arrow == null:
		push_warning("This note has no arrow node, making it impossible to be spawned ", data)
		queue_free()
		return

	do_follow = is_instance_valid(receptor)
	position = Vector2(INF, -INF)

	if is_sustain or data.debug:
		og_len = data.s_len
		make_sustain()

func make_sustain() -> void:
	if not sustain_data.has("hold_texture") or not sustain_data.has("tail_texture"):
		return

	if is_instance_valid(receptor) and receptor.skin.propagate_call("make_sustain", [self]) == 0:
		return

	clip_rect = Control.new()
	clip_rect.clip_contents = true
	add_child(clip_rect)
	move_child(clip_rect, 0)

	var tail: = TextureRect.new()
	tail.texture = sustain_data["tail_texture"]
	tail.layout_mode = 1
	tail.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tail.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tail.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tail.use_parent_material = true

	var hold: = TextureRect.new()
	hold.texture = sustain_data["hold_texture"]
	hold.layout_mode = 1
	hold.set_anchors_preset(Control.PRESET_FULL_RECT)
	hold.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -tail.texture.get_height() + 1.0)
	hold.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hold.grow_vertical = Control.GROW_DIRECTION_BOTH
	hold.use_parent_material = true

	clip_rect.size.x = maxf(tail.texture.get_width(), hold.texture.get_width())
	clip_rect.position.x -= clip_rect.size.x * 0.5
	clip_rect.add_child(hold)
	clip_rect.add_child(tail)

	clip_rect.scale.y = scroll
	clip_rect.modulate.a = 0.6
	# clip behind receptors
	clip_rect.z_index = -1 if not $"../../".debug else 1
	if sustain_data.has("use_parent_material"):
		clip_rect.use_parent_material = bool(sustain_data["use_parent_material"])

func pop_splash() -> void:
	if splash == null:
		return

	if is_instance_valid(receptor) and receptor.skin.propagate_call("pop_splash", [self]) == 0:
		return
