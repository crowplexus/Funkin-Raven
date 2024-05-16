extends Sprite2D

var origin: Vector2 = Vector2.ONE

func _ready() -> void:
	origin = offset

func _process(_delta: float) -> void:
	if scale.x != 0.8:
		scale = Vector2(
			Tools.exp_lerp(scale.x, 0.8, 30),
			Tools.exp_lerp(scale.y, 0.8, 30)
		)

func bump() -> void:
	scale = Vector2.ONE
