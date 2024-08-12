extends Control
class_name GameHUD # extend this when making a custom HUD

func reset_positions() -> void:
	# required for the pause menu when changing scroll direction during gameplay.
	pass
func setup_healthbar() -> void:
	# this sets up health icons and such before gameplay starts.
	pass
func set_icons(_icons: Array[HealthIcon]) -> void:
	# this is to allow for us to change the icons during gameplay (for example)
	pass
func get_health(_next: float, _current: float, _delta: float) -> float:
	# this is optional, but if you want a custom fill effect for your health bar, this is it.
	return _next
func update_score_text(_tally: Tally, _is_tap: bool) -> void:
	# required, called whenever you hit a note.
	pass
func display_judgement(_hit_result: Note.HitResult, _combo_group: Control) -> void:
	# optional, this is to allow for custom judgement pop ups
	pass
func display_combo(_hit_result: Note.HitResult, _combo_group: Control) -> void:
	# optional, this is to allow for custom combo pop ups
	pass
