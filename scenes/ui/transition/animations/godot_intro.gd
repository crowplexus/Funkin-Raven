# recreating the flixel transition
extends Control

signal started()
signal finished()

@onready var anim_player: AnimationPlayer = $"animation_player"
@onready var timer: Timer = $"bomb"
var _leave_c: int = 0

func _ready() -> void:
	await RenderingServer.frame_post_draw
	if get_tree().current_scene == self:
		start()

func start(out: bool = false, speed: float = 1.0) -> void:
	anim_player.seek(0.0)
	anim_player.play("in" if not out else "out", -1, speed)
	started.emit()
	# timer for finishing #
	timer.start(anim_player.current_animation_length)
	await timer.timeout
	finished.emit()
	if get_tree().current_scene == self:
		start(true, speed)
	if out:
		if get_tree().current_scene == self:
			get_tree().change_scene_to_packed(Globals.STARTING_SCENE)
		else:
			queue_free()


func _unhandled_key_input(e: InputEvent):
	if get_tree().current_scene != self:
		return
	if e.pressed:
		_leave_c += 1
		if _leave_c > 2:
			get_tree().change_scene_to_packed(Globals.STARTING_SCENE)
