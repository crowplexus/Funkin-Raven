extends Sprite2D

func _process(delta: float):
	if scale.x != 0.8:
		scale = Vector2(
			Tools.lerp_fix(scale.x, 0.8, delta, 10),
			Tools.lerp_fix(scale.y, 0.8, delta, 10)
		)

func bump():
	if Conductor.beat % 2 == 0: scale = Vector2.ONE
	else: scale = Vector2(0.8, 0.8)
