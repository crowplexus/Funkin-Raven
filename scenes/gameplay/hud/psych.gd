extends Control

@onready var health_bar: = $"health_bar"
@onready var time_bar: = $"timer"
@onready var time_label: = $"timer/label"
@onready var status_label: = $"status_label"

var tb_twn: Tween


func _ready() -> void:
	match Preferences.scroll_direction:
		1:
			health_bar.position.y = 80
			status_label.position.y = 115
			time_bar.position.y = size.y - 34

	time_bar.modulate.a = 0.0
	tb_twn = create_tween().set_ease(Tween.EASE_IN).bind_node(health_bar)
	tb_twn.tween_property(time_bar, "modulate:a", 1.0, 1.5 * Conductor.crotchet)
	time_bar.visible = Preferences.show_timer


func setup_healthbar() -> void:
	var stage: StageBG = get_tree().current_scene.get("stage")
	if is_instance_valid(stage):
		# very messy icon stuff
		if stage.has_node("player2") and stage.get_node("player2") is Character:
			health_bar.get_child(0).texture = stage.get_node("player2").health_icon
		if stage.has_node("player1") and stage.get_node("player1") is Character:
			health_bar.get_child(1).texture = stage.get_node("player1").health_icon


func _process(_delta: float) -> void:
	if Conductor.active:
		update_time_bar()


func update_score_text(hit_result: Note.HitResult, _is_tap: bool) -> void:
	if hit_result.player.botplay == true:
		status_label.text = "BOTPLAY"
		return

	var acc: float = snappedf(hit_result.player.accuracy, 0.01)
	var rating_fc: String = Scoring.get_clear_flag(hit_result.player.jhit_regis)
	var acc_str: String = " (%s%%) - %s" % [ acc, "Clear" if rating_fc.is_empty() else rating_fc ]

	var text: String = "Score: %s | Misses: %s | Rating: %s" % [
		hit_result.player.score, hit_result.player.misses,
		get_rating(acc) + acc_str,
	]
	match Preferences.status_display_mode:
		1: status_label.text = text.substr(text.find("|") + 1, text.length())
		2: status_label.text = text.substr(0, text.find(" | "))
		_: status_label.text = text


func update_time_bar() -> void:
	if time_bar.visible and Conductor.time >= 0.0:
		time_bar.value = absf(Conductor.time / Conductor.length) * time_bar.max_value
		time_label.text = "%s" % [
			Globals.format_to_time(Conductor.length - Conductor.time)
		]


func get_rating(acc: float):
	match acc: # "use a for loop" this is literally faster and easier readable please st
		_ when acc >= 100: return "Perfect!!"
		_ when acc >= 90: return "Sick!"
		_ when acc >= 80: return "Great"
		_ when acc >= 70: return "Good"
		_ when acc == 69: return "Nice"
		_ when acc >= 60: return "Meh"
		_ when acc >= 50: return "Bruh"
		_ when acc >= 40: return "Bad"
		_ when acc >= 30: return "Shit"
		_ when acc <= 20: return "You Suck!"
		_: return "?"
