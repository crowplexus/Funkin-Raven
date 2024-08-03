extends Node2D

const HOLD_FRAMES: SpriteFrames = preload(
	"res://assets/sprites/noteskins/fnf/NOTE_assets.res")

@onready var hold_container: Control = $"hold_container"
@onready var splash_spr: AnimatedSprite2D = $"splash"
@onready var cover_spr: AnimatedSprite2D = $"cover"

var note: Note
var tap: Variant
var hold: TextureRect
var tail: TextureRect
var column: int = 0
var _displayed_covers: Array[CanvasItem] = []

#region Sprite Creation

func _ready() -> void:
	if not is_instance_valid(note):
		return
	#var col: Color = Note.get_colour(note.time, column)
	#material.set_shader_parameter("colour", col)

	column = note.column % 4
	#if note.notefield:
	#	column = column % note.notefield.receptors.size()

	tap = $"tap"
	tap.frame = column
	if note.receptor and not tap.top_level:
		tap.rotation = note.receptor.rotation
	if note.hold_length != 0.0:
		make_hold()

func make_hold() -> void:
	if not note.debug_mode:
		reset_scroll(note.scroll)
	if Preferences.hold_layer == 1:
		move_child(hold_container, 0)
	hold = Note.make_dummy_hold()
	hold.texture = HOLD_FRAMES.get_frame_texture("%s hold" % column, 0)
	hold_container.add_child(hold)
	tail = Note.make_dummy_hold()
	var tail_tex: = HOLD_FRAMES.get_frame_texture("%s hold" % column, 1)
	tail.size = Vector2(tail_tex.get_width(), tail_tex.get_height())
	tail.position.y = hold.get_end().y
	tail.texture = tail_tex
	tail.name = "tail"
	hold_container.add_child(tail)
	update_hold_size()

func reset_scroll(scroll: Vector2) -> void:
	if hold_container:
		hold_container.scale *= scroll

func display_splash() -> void:
	if not note.receptor:
		return
	var splash: = splash_spr.duplicate() as AnimatedSprite2D
	splash.modulate.a = 0.6
	splash.top_level = true
	splash.visible = true
	splash.global_position = note.receptor.global_position
	note.receptor.add_child(splash)
	splash.play("splash%s %s" % [ column, randi_range(1, 2) ])
	splash.animation_finished.connect(splash.queue_free)

func display_cover() -> void:
	if not note.receptor:
		return
	var cover: = cover_spr.duplicate() as AnimatedSprite2D
	cover.animation_finished.connect(func():
		match cover.animation:
			_ when cover.animation.begins_with("begin"):
				cover.frame = 0
				cover.play("progress%s" % column)
			_ when cover.animation.begins_with("finish"):
				cover.queue_free()
	)
	cover.visible = true
	add_child(cover)
	_displayed_covers.append(cover)
	cover.frame = 0
	cover.play("begin%s" % column)
#endregion
#region Behaviour

func update_hold_size(custom_size: float = 0.0) -> void:
	if not hold or note.hold_progress <= 0.0:
		return
	if not note.moving and tap.visible:
		tap.hide()

	var end_size: float = custom_size if custom_size != 0.0 else note.hold_progress
	var hold_calc: float = (600.0 * absf(note.real_speed)) * end_size
	var tail_size: float = tail.size.y #tail.texture.get_height()
	hold.size.y = hold_calc - 0.05
	hold_container.size = Vector2(hold.size.x, hold_calc + tail_size)
	tail.position.y = (hold.position.y + hold.size.y)
	#hold.size.y /= absf(self.scale.y)
	for cover: CanvasItem in _displayed_covers:
		if note.hold_progress > 0.0:
			cover.play("progress%s" % column)

func finish() -> void:
	var valid: bool = note and note.hit_result and Preferences.hold_covers == 2 and not note.hit_result.player.autoplay
	if note.hold_progress <= 0.0 and not _displayed_covers.is_empty():
		for cover: CanvasItem in _displayed_covers:
			if valid:
				var dupe: = cover.duplicate()
				note.receptor.add_child(dupe)
				dupe.play("finish%s" % column)
				dupe.animation_finished.connect(dupe.queue_free)
				cover.queue_free()
			else:
				cover.queue_free()

func on_hit(data: Note) -> void:
	if not data or not data.hit_result:
		return

	if data.hit_result and data.hit_result.judgment:
		var result: Note.HitResult = data.hit_result
		var splash: bool = false
		if result.judgment.splash:
			match Preferences.note_splashes:
				0: splash = false
				1: splash = result.player and not result.player.autoplay
				2: splash = is_instance_valid(result.player)
		match result.judgment.name:
			"perfect" when data.hold_progress > 0.0:
				if splash: display_splash()
				if Preferences.hold_covers > 0:
					display_cover()
			_:
				if splash: display_splash()
				if data.hold_progress > 0.0 and Preferences.hold_covers > 0:
					display_cover()

func on_miss(_column: int) -> void:
	modulate.a = 0.3

#endregion
