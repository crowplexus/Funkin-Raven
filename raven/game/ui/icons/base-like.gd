extends Sprite2D

var origin: Vector2 = Vector2.ONE

func _ready():
	origin = offset

func _process(delta: float):
	if scale.x != 0.8:
		scale = Vector2(
			Tools.lerp_fix(scale.x, 0.8, delta, 30),
			Tools.lerp_fix(scale.y, 0.8, delta, 30)
		)

func bump():
	scale = Vector2.ONE
