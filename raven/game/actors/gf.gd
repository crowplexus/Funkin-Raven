extends Character

func sing(dir: int, force: bool = false):
	super(dir, force)
	match dir:
		0: _dance_step = 1
		1: _dance_step = 0
		2,3:
			_dance_step = 1 if _dance_step != 1 else 0
