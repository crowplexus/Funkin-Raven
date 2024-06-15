extends Node2D

const HOLD_FRAMES: SpriteFrames = preload("res://assets/sprites/ui/normal/NOTE_assets.res")

var note: Note

@onready var hold_container: Control = $"hold_container"
@onready var splash: AnimatedSprite2D = $"splash"

var tap: Sprite2D
var hold: TextureRect
var tail: TextureRect


func _ready() -> void:
	if not is_instance_valid(note):
		return

	tap = $"tap"
	tap.frame = note.column
	if note.hold_length > 0.0:
		if not note.debug_mode:
			hold_container.scale *= note.scroll
			if Preferences.hold_layer == 1:
				hold_container.z_index = -1

		hold = hold_container.get_node("hold")
		hold.texture = HOLD_FRAMES.get_frame_texture("%s hold" % note.column, 0)
		var scroll_speed: float = note.speed
		match Preferences.scroll_speed_behaviour:
			1: scroll_speed += Preferences.scroll_speed
			2: scroll_speed  = Preferences.scroll_speed
		hold.size.y = absf((600.0 * absf(scroll_speed)) * note.hold_length	)

		tail = $"hold_container/hold".duplicate()
		var tail_tex: = HOLD_FRAMES.get_frame_texture("%s hold" % note.column, 1)
		tail.size = Vector2(tail_tex.get_width(), tail_tex.get_height())
		tail.position.y = hold.get_end().y
		tail.texture = tail_tex
		tail.name = "tail"
		hold_container.add_child(tail)
		update_hold_size()


func update_hold_size() -> void:
	if not is_instance_valid(hold) or note.hold_length == 0.0:
		return

	if note.update_hold and tap.visible:
		tap.hide()

	if is_instance_valid(hold):
		hold.size.y = absf(600.0 * absf(note.speed)) * note.hold_length
		#hold.size.y /= absf(self.scale.y)
		if is_instance_valid(tail):
			tail.position.y = hold.position.y + hold.size.y


func hit_behaviour(result: Note.HitResult) -> void:
	if result.judgment.splash:
		display_splash()


func miss_behaviour(_note: Note) -> void:
	modulate.a = 0.4
	pass


func display_splash() -> void:
	if not is_instance_valid(note.receptor):
		return

	var splash_item: = splash.duplicate() as AnimatedSprite2D
	splash_item.global_position = note.receptor.global_position
	splash_item.modulate.a = 0.6
	splash_item.top_level = true
	splash_item.visible = true
	note.receptor.add_child(splash_item)
	splash_item.play("splash%s %s" % [ note.column, randi_range(1, 2) ])
	splash_item.animation_finished.connect(splash_item.queue_free)
