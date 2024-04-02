extends Sprite2D

var origin: Vector2 = Vector2.ONE

func _ready():
	origin = offset

func _process(delta: float):
	if scale.x != 0.8:
		scale = Vector2(
			Tools.lerp_fix(scale.x, 0.8, delta, 5),
			Tools.lerp_fix(scale.y, 0.8, delta, 5)
		)

func bump():
	# i know this is unconventional / sucks
	# shut up.
	if Conductor.beat % 1 == 0:
		if get_index() == 0: scale = Vector2.ONE
		else: scale = Vector2(0.8, 0.8)
	if Conductor.beat % 2 == 0:
		if get_index() == 1: scale = Vector2.ONE
		else: scale = Vector2(0.8, 0.8)
