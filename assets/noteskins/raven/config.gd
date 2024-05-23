extends NoteSkin

var angles: Array[int] = [-90, -180, 0, 90]
var colors: PackedColorArray = [
	Color("#C24B99"),
	Color("#00FFFF"),
	Color("#12FA05"),
	Color("#F9393F"),
]
var cool_shader: ShaderMaterial = ShaderMaterial.new()


func _ready() -> void:
	colour_mode = SkinColour.CUSTOM
	cool_shader.shader = load("res://assets/shaders/colormask_red.gdshader")
	receptor.sprite_frames = load("res://assets/noteskins/raven/notes.xml")

	receptor.rotation_degrees = angles[receptor.get_index()]
	receptor.frame = 0
	receptor.play("receptor")
	# correct offset
	receptor.position = Vector2.ZERO
	if receptor.get_index() != 0:
		receptor.position.x += (160 * receptor.get_index())
	else:
		receptor.position.y += 5


func assign_arrow(note: Note) -> int:
	var frames: = load("res://assets/noteskins/raven/notes.xml") as SpriteFrames
	note.get_node("arrow").texture = frames.get_frame_texture("note", 0)
	note.arrow = note.get_node("arrow")
	note.sustain_data = {
		"hold_texture": frames.get_frame_texture("hold piece", 0),
		"tail_texture": frames.get_frame_texture("hold end", 0),
		"use_parent_material": true,
	}
	note.arrow.rotation_degrees = note.receptor.rotation_degrees
	note.splash = AnimatedSprite2D.new()
	note.splash.sprite_frames = load("res://assets/noteskins/raven/splashes.res")

	note.material = cool_shader
	note.material.set_shader_parameter("new_color", colors[receptor.get_index()])
	note.arrow.use_parent_material = true

	return 0 # stop original func


func pop_splash(note: Note) -> int:
	if note.splash == null:
		return 1

	var firework: = note.splash.duplicate() as AnimatedSprite2D
	firework.top_level = true
	firework.global_position = receptor.global_position
	firework.material = note.material
	firework.frame = 0
	receptor.add_child(firework)

	firework.play("splash")
	firework.animation_finished.connect(firework.queue_free)
	return 0


func enemy_hit(note: Note) -> void:
	note.receptor.glow_up(note.arrow.visible or note.receptor.frame_progress > 0.05)
	note.receptor.reset_timer = 0.1 + note.data.s_len


func do_action(action: int, _force: bool = false) -> int:
	match action:
		Receptor.ActionType.GHOST: receptor.modulate.v = 0.5
		Receptor.ActionType.GLOW: receptor.modulate.v = 1.5
		_: receptor.modulate.v = 1.0
	return 0
