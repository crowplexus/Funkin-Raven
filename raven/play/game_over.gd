extends Node2D

@onready var rect: ColorRect = $rect
@onready var character: Character = get_child(1) as Character
@onready var camera: Camera2D = get_viewport().get_camera_2d()

var ending: bool = false

var rect_tween: Tween
var camera_tween: Tween

func _ready() -> void:
	await RenderingServer.frame_post_draw

	SoundBoard.play_sfx(character.sound_on_death)
	character.play_anim("firstDeath", true)

	rect.color = Color.PALE_VIOLET_RED

	rect_tween = create_tween().bind_node(rect)
	rect_tween.tween_property(rect, "color", Color(0, 0, 0, 0.8), 0.3) \
	.set_delay(0.1)

	if camera != null:
		camera_tween = create_tween().bind_node(camera)
		camera_tween.tween_property(camera, "zoom", Vector2.ONE, 1.0) \
		.set_delay(0.05)

	character.anim_player.animation_finished.connect(func(anim_name: StringName) -> void:
		match anim_name:
			"firstDeath":
				if ending: return
				character.play_anim("deathLoop", true)
				SoundBoard.play_track(character.music_on_death)
			"deathConfirm":
				create_tween().tween_property(character, "modulate:a", 0.0, 0.8) \
				.finished.connect(func() -> void:
					get_tree().paused = false
					Tools.refresh_scene()
				)
	)

	await get_tree().create_timer(0.5).timeout
	if camera != null:
		camera.position_smoothing_speed = 0.8
		camera.process_mode = Node.PROCESS_MODE_ALWAYS
		camera.position = character.position + character.camera_offset

func _unhandled_key_input(e: InputEvent) -> void:
	if ending or not e.pressed: return

	if e.is_action("ui_accept") or e.is_action("ui_cancel"):
		ending = true
		SoundBoard.stop_tracks()
		SoundBoard.stop_sounds()
		PlayField.play_manager.reset()

	if e.is_action("ui_accept"):
		if camera != null:
			if camera_tween != null: camera_tween.kill()
			camera_tween = create_tween().set_trans(Tween.TRANS_SINE).bind_node(camera)
			camera_tween.tween_property(camera, "zoom", Vector2(1.05, 1.05), 0.35) \
			.set_delay(0.1)

		if rect_tween != null: rect_tween.kill()
		rect_tween = create_tween().set_trans(Tween.TRANS_BACK).bind_node(rect)
		rect_tween.tween_property(rect, "color", Color.BLACK, 0.5)

		SoundBoard.play_sfx(character.sound_on_retry)
		character.play_anim("deathConfirm", true)

	if e.is_action("ui_cancel"):
		SoundBoard.play_sfx(Menu2D.CANCEL_SOUND)
		PlayField.death_count = 0

		if camera_tween != null: camera_tween.kill()

		camera_tween = create_tween().set_ease(Tween.EASE_OUT)
		camera_tween.tween_property(character, "modulate:a", 0.0, 0.8)

		if rect_tween != null: rect_tween.kill()

		rect_tween = create_tween().set_ease(Tween.EASE_OUT)
		rect_tween.tween_property(rect, "color", Color.BLACK, 0.5) \
		.set_delay(0.3)

		await rect_tween.finished

		get_tree().paused = false
		var next_menu: StringName = "freeplay"
		if PlayField.play_manager.play_mode == 0:
			next_menu = "story_menu"

		Tools.switch_scene(load("res://raven/menu/%s.tscn" % next_menu))
