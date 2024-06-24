extends Control

@onready var health_bar: = $"health_bar"
@onready var status_label: = $"status_label"


func _ready() -> void:
	match Preferences.scroll_direction:
		1:
			health_bar.position.y = 80
			status_label.position.y = 110


func setup_healthbar() -> void:
	var stage: StageBG = get_tree().current_scene.get("stage")
	if is_instance_valid(stage):
		# very messy icon stuff
		if stage.has_node("player2") and stage.get_node("player2") is Character:
			health_bar.get_child(0).texture = stage.get_node("player2").health_icon
		if stage.has_node("player1") and stage.get_node("player1") is Character:
			health_bar.get_child(1).texture = stage.get_node("player1").health_icon

func update_score_text(hit_result: Note.HitResult, _is_tap: bool) -> void:
	if hit_result.player.botplay == true:
		status_label.text = "BotPlay Enabled"
		return
	var acc: float = snappedf(hit_result.player.accuracy, 0.01)
	status_label.text = "Score:%s" % hit_result.player.score
