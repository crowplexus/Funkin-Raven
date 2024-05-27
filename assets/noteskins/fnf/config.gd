extends NoteSkin

var _last_action: int = 0

var hold_cover: Sprite2D

# setup the fnf noteskin
func _ready() -> void:
	receptor.sprite_frames = load("res://assets/noteskins/fnf/notes.res")
	receptor.become_static(true)
	# correct offset
	receptor.position = Vector2.ZERO
	if receptor.get_index() != 0:
		receptor.position.x += 10 + (160 * receptor.get_index())
	else:
		receptor.position.y -= 5

	if not receptor.parent.is_cpu:
		receptor.animation_finished.connect(func():
			if receptor.animation.ends_with("confirm"):
				receptor.become_ghost(true)
		)

	hold_cover = Sprite2D.new()
	hold_cover.texture = load("res://assets/noteskins/fnf/hold_judgments_temp.png")
	hold_cover.hframes = 1
	hold_cover.vframes = 2

func display_hold_cover(is_fully_held: bool = false) -> void:
	var cover: Sprite2D = hold_cover.duplicate()
	cover.frame = 0 if is_fully_held else 1
	cover.scale = Vector2(1.5, 1.5)
	receptor.add_child(cover)

	var twn: Tween = Conductor.get_tree().create_tween().bind_node(cover)
	twn.set_parallel(true)

	twn.tween_property(cover, "scale", Vector2(2.0, 2.0	), 0.2) \
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_ELASTIC)
	twn.tween_property(cover, "position:y", cover.position.y + 150 * receptor.scroll_dir, 0.15) \
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	twn.tween_property(cover, "modulate:a", 0.0, 0.5) \
	.set_ease(Tween.EASE_OUT).set_delay(0.1)

	twn.finished.connect(cover.queue_free)

func assign_arrow(note: Note) -> int:
	var frames: = load("res://assets/noteskins/fnf/notes.res") as SpriteFrames
	var color: StringName = Chart.NoteData.color_to_str(note.data.column)
	note.get_node("arrow").texture = frames.get_frame_texture(color, 0)
	note.arrow = note.get_node("arrow")
	note.sustain_data = {
		"hold_texture": frames.get_frame_texture(color + " hold piece", 0),
		"tail_texture": frames.get_frame_texture(color + " hold end", 0),
	}
	note.splash = AnimatedSprite2D.new()
	note.splash.sprite_frames = load("res://assets/noteskins/fnf/splashes.res")
	return 0 # stop original func

func pop_splash(note: Note) -> int:
	if note.splash == null:
		return 1

	var firework: = note.splash.duplicate() as AnimatedSprite2D
	firework.top_level = true
	firework.global_position = receptor.global_position
	firework.frame = 0
	receptor.add_child(firework)

	var color: StringName = Chart.NoteData.color_to_str(note.data.column)
	firework.play("note impact %s %s" % [ randi_range(1, 2), color ])
	firework.animation_finished.connect(firework.queue_free)
	return 0


func enemy_hit(note: Note) -> void:
	var force_receptor: bool = note.arrow.visible or note.receptor.frame_progress > 0.05
	if note.is_sustain: note.receptor.glow_hold(force_receptor)
	else: note.receptor.glow_up(force_receptor)
	note.receptor.reset_timer = 0.1 + note.data.s_len

func do_action(action: int, force: bool = false) -> int:
	var direction_str: StringName = Chart.NoteData.column_to_str(receptor.get_index())
	var action_anim: StringName = "arrow" + direction_str.to_upper()

	match action:
		Receptor.ActionType.GHOST:
			action_anim = "%s press"	% direction_str
		Receptor.ActionType.GLOW, Receptor.ActionType.HOLD:
			action_anim = "%s confirm"	% direction_str

	if force or _last_action != action:
		receptor.frame = 0
	receptor.play(action_anim)
	_last_action = action
	return 0
