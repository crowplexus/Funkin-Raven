extends Character

func _ready() -> void:
	if _faces_left:
		singing_steps[0] = "singRIGHT"
		singing_steps[3] = "singLEFT"
		scale.x *= -1
	dance(true)

