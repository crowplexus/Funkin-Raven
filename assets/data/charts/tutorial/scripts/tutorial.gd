extends Modchart

@onready var player1: = game.get_node("player1") as Character
@onready var player2: = game.get_node("player2") as Character

func _ready() -> void:
	if player2 != null:
		player2.position.x += 30

func on_beat(beat: int) -> void:
	if player2 != null and player2.actor_name.find("gf") != -1 and beat % 16 == 15 and beat > 16 and beat < 48:
		player2.animation_context = Character.AnimContext.SPECIAL
		player2.stop_current_anim()
		player2.play_anim("hey", true)
		player2.idle_cooldown = (13 * Conductor.semiquaver)

		if player1 != null:
			player1.animation_context = Character.AnimContext.SPECIAL
			player1.stop_current_anim()
			player1.play_anim("hey", true)
			player1.idle_cooldown = (13 * Conductor.semiquaver)
