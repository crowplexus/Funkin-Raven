extends NoteSkin

var _last_action: int = 0

# setup the fnf noteskin
func _ready() -> void:
	receptor.sprite_frames = load("res://assets/noteskins/fnf/notes.xml")
	receptor.become_static(true)
	# correct offset
	receptor.position = Vector2.ZERO
	if receptor.get_index() != 0:
		receptor.position.x += 10 + (160 * receptor.get_index())

func assign_arrow(note: Note) -> int:
	var frames: = load("res://assets/noteskins/fnf/notes.xml") as SpriteFrames
	var color: StringName = Chart.NoteData.color_to_str(note.data.column)
	note.get_node("arrow").texture = frames.get_frame_texture(color, 0)
	note.arrow = note.get_node("arrow")
	note.sustain_data = {
		"hold_texture": frames.get_frame_texture(color + " hold piece", 0),
		"tail_texture": frames.get_frame_texture(color + " hold end", 0),
	}
	note.splash = AnimatedSprite2D.new()
	note.splash.sprite_frames = load("res://assets/noteskins/fnf/splashes.xml")
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
	note.receptor.glow_up(note.arrow.visible or note.receptor.frame_progress > 0.05)
	note.receptor.reset_timer = 0.1 + note.data.s_len

func do_action(action: int, force: bool = false) -> int:
	var direction_str: StringName = Chart.NoteData.column_to_str(receptor.get_index())
	var action_anim: StringName = "arrow" + direction_str.to_upper()

	match action:
		Receptor.ActionType.GHOST:
			action_anim = direction_str + " press"
		Receptor.ActionType.GLOW:
			action_anim = direction_str + " confirm"

	if force or _last_action != action:
		receptor.frame = 0
	receptor.play(action_anim)
	_last_action = action
	return 0
