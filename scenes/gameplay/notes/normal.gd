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
	if note.hold_progress > 0.0:
		make_hold()


func make_hold() -> void:
	if not note.debug_mode:
		reset_scroll(note.scroll)
	if Preferences.hold_layer == 1:
		move_child(hold_container, 0)
	hold = Note.make_dummy_hold()
	hold.texture = HOLD_FRAMES.get_frame_texture("%s hold" % column, 0)
	hold.size.y = absf((400.0 * absf(note.real_speed)) * note.hold_progress)
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
	var splash_item: = splash_spr.duplicate() as AnimatedSprite2D
	splash_item.modulate.a = 0.6
	splash_item.visible = true
	note.receptor.add_child(splash_item)
	splash_item.play("splash%s %s" % [ column, randi_range(1, 2) ])
	splash_item.animation_finished.connect(splash_item.queue_free)


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

func update_hold_size() -> void:
	if not hold or note.hold_progress == 0.0:
		return
	if note.update_hold and tap.visible:
		if Preferences.hold_layer == 1:
			hold_container.z_index = -1
		tap.hide()
	hold.size.y = (600.0 * absf(note.real_speed)) * note.hold_progress
	#hold.size.y /= absf(self.scale.y)
	if tail:
		tail.position.y = hold.position.y + hold.size.y
	for cover: CanvasItem in _displayed_covers:
		if note.hold_progress > 0.0:
			cover.play("progress%s" % column)

func finish() -> void:
	var valid: bool = note and note.hit_result #and not note.hit_result.player.botplay
	if valid and note.hold_progress <= 0.0 and not _displayed_covers.is_empty():
		for cover: CanvasItem in _displayed_covers:
			var dupe: = cover.duplicate()
			note.receptor.add_child(dupe)
			dupe.play("finish%s" % column)
			dupe.animation_finished.connect(dupe.queue_free)


func on_hit(hit_note: Note) -> void:
	if not hit_note:
		return

	if hit_note.hit_result and hit_note.hit_result.judgment:
		var result: Note.HitResult = hit_note.hit_result
		if hit_note.moving:
			var splash: bool = result.judgment.splash
			if splash == true: match Preferences.note_splashes:
				0: splash = false
				1: splash = result.player and not result.player.botplay
				2: splash = is_instance_valid(result.player)

			match result.judgment.name:
				"perfect" when note.hold_progress > 0.0:
					if splash: display_splash()
					display_cover()
				_ when splash:
					display_splash()
					if hit_note.hold_progress > 0.0:
						display_cover()


func on_miss(_column: int) -> void:
	modulate.a = 0.3

#endregion
