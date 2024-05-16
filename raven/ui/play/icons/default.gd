extends Sprite2D

func _process(_delta: float) -> void:
	if scale.x != 0.8:
		scale = Vector2(
			Tools.exp_lerp(scale.x, 0.8, 10),
			Tools.exp_lerp(scale.y, 0.8, 10)
		)

func bump() -> void:
	if Conductor.beat % 2 == 0: scale = Vector2.ONE
	else: scale = Vector2(0.8, 0.8)
