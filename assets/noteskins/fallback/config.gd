extends NoteSkin

func _ready() -> void:
	receptor.sprite_frames = load("res://assets/noteskins/fallback/notes.res")
	receptor.play("default")
	receptor.frame = 0

# OVERRIDEN FUNCTIONS #

# these are function from the receptor.gd script
# returning 0 in these functions makes it so you override
# the behaviour of the hardcoded function, providing your own
# tailored to your own noteskin.

func do_action(action: int, _force: bool = false) -> int:
	var action_visibility: float = 1.0
	var action_scale: Vector2 = Vector2.ONE

	match action:
		Receptor.ActionType.GHOST:
			action_visibility = 0.5
			action_scale = Vector2(0.8, 0.8)
		Receptor.ActionType.GLOW, Receptor.ActionType.HOLD:
			action_visibility = 1.5
			action_scale = Vector2(1.1, 1.1)

	receptor.modulate.v = action_visibility
	receptor.scale = action_scale
	return 0
