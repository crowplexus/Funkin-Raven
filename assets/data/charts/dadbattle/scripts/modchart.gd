extends Modchart
func _process(_delta: float):
	match Conductor.step:
		128:
			game.get_node("player2").visible = false
			game.playfield.health_bar.get_child(1).visible = false
# happy april fools :3
