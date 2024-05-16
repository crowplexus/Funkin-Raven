extends Sprite2D

var origin: Vector2 = Vector2.ONE

func _ready() -> void:
	origin = offset

func _process(_delta: float) -> void:
	if scale.x != 0.8:
		scale = Vector2(
			Tools.exp_lerp(scale.x, 0.8, 5),
			Tools.exp_lerp(scale.y, 0.8, 5)
		)

func bump() -> void:
	# i know this is unconventional / sucks
	# shut up.
	if Conductor.beat % 1 == 0:
		if get_index() == 0: scale = Vector2.ONE
		else: scale = Vector2(0.8, 0.8)
	if Conductor.beat % 2 == 0:
		if get_index() == 1: scale = Vector2.ONE
		else: scale = Vector2(0.8, 0.8)
