extends Node2D

const HOLD_FRAMES: SpriteFrames = preload("res://assets/sprites/ui/normal/notes/notes.res")

var note: Note

@onready var hold_container: Control = $"hold_container"

@onready var splash_spr: AnimatedSprite2D = $"splash"
@onready var cover_spr: AnimatedSprite2D = $"cover"

var tap
var hold: TextureRect
var tail: TextureRect

var _covers: Array[AnimatedSprite2D] = []


func _ready() -> void:
	if not is_instance_valid(note):
		return

	match Preferences.note_colouring_mode:
		0:
			var col: Color = Preferences.note_colours[0][note.column]
			material.set_shader_parameter("colour", col)
		1:
			var beat_time: float = Conductor.time_to_beat(note.time)
			var col: Color = Preferences.note_colours[1][Note.get_quant(beat_time)]
			material.set_shader_parameter("colour", col)

	tap = $"tap"
	if is_instance_valid(note.receptor):
		tap.rotation = note.receptor.rotation

	if note.hold_length > 0.0:
		if not note.debug_mode:
			hold_container.scale *= note.scroll
			if Preferences.hold_layer == 1:
				move_child(hold_container, 0)

		hold = $"hold_container/hold"
		hold.texture = HOLD_FRAMES.get_frame_texture("hold", 0)
		hold.size.y = absf((400.0 * absf(note.real_speed)) * note.hold_length)
		hold.use_parent_material = true

		tail = $"hold_container/hold".duplicate()
		var tail_tex: = HOLD_FRAMES.get_frame_texture("hold", 1)
		tail.size = Vector2(tail_tex.get_width(), tail_tex.get_height())
		tail.position.y = hold.get_end().y
		tail.use_parent_material = true
		tail.texture = tail_tex
		tail.name = "tail"
		hold_container.add_child(tail)
		update_hold_size()


func update_hold_size() -> void:
	if not is_instance_valid(hold) or note.hold_length == 0.0:
		return

	if note.update_hold and tap.visible:
		tap.hide()
	hold.size.y = (600.0 * absf(note.real_speed)) * note.hold_length
	#hold.size.y /= absf(self.scale.y)
	if is_instance_valid(tail):
		tail.position.y = hold.position.y + hold.size.y

	for cover in _covers:
		if Conductor.ibeat % 1 == 0:
			#print_debug("updating cover")
			if cover.animation.begins_with("begin"):
				await cover.animation_finished
			cover.play("progress", 0.9)


func finish() -> void:
	if note.update_hold and Conductor.ibeat % 1 == 0:
		for cover in _covers:
			#print_debug("updating cover")
			cover.play("finish")


func hit_behaviour(result: Note.HitResult) -> void:
	if not is_instance_valid(result):
		return
	if result.judgment.splash and Preferences.note_splashes:
		display_splash()
		if not note.moving and result.data.hold_length > 0.0:
			display_cover()


func miss_behaviour(_column: int) -> void:
	modulate.a = 0.3


func display_splash() -> void:
	if not is_instance_valid(note.receptor):
		return

	var splash_item: = splash_spr.duplicate() as AnimatedSprite2D
	splash_item.global_position = note.receptor.global_position
	splash_item.material = material.duplicate()
	splash_item.modulate.a = 0.6
	splash_item.top_level = true
	splash_item.visible = true
	note.receptor.add_child(splash_item)
	splash_item.play("note impact %s" % [ randi_range(1, 2) ])
	splash_item.animation_finished.connect(splash_item.queue_free)


func display_cover() -> void:
	if not is_instance_valid(note.receptor):
		return

	var cover: = cover_spr.duplicate() as AnimatedSprite2D
	cover.material = material.duplicate()
	cover.top_level = true
	cover.visible = true
	note.receptor.add_child(cover)
	cover.global_position = note.receptor.global_position

	cover.play("begin")
	cover.animation_finished.connect(func():
		if cover.animation.begins_with("finish"):
			cover.queue_free()
	)
	_covers.append(cover)
