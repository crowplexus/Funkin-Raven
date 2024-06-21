# recreating the flixel transition
extends Control

signal started()
signal finished()

@onready var sprite: Sprite2D = $"sprite"
@onready var anim_player: AnimationPlayer = $"sprite/animation_player"
@onready var timer: Timer = $"bomb"


func start(out: bool = false, speed: float = 1.0) -> void:
	anim_player.seek(0.0)
	anim_player.play("in" if not out else "out", -1, speed)
	started.emit()
	# timer for finishing #
	timer.start(anim_player.current_animation_length)
	await timer.timeout
	finished.emit()
	if out: queue_free()

