extends Character

func _ready():
	if is_player and not _is_real_player:
		scale.x *= -1
	dance(true)
