extends Character


func sing(column: int, force: bool = false, suffix: String = "") -> void:
	super(column, force, suffix)
	match suffix:
		"-alt" when column == 1:
			animation_context = 2
			idle_cooldown = (60 * Conductor.semiquaver)
