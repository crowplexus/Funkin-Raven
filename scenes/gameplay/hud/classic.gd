extends Control

@onready var health_bar: TextureProgressBar = $"health_bar"
@onready var icon_animation: AnimationPlayer = $"health_bar/animation_player"
@onready var status_label: Label = $"status_label"
@export var icon_bump_interval: int = 1


func _ready() -> void:
	reset_positions()
	Conductor.ibeat_reached.connect(icon_thingy)


func reset_positions() -> void:
	match Preferences.scroll_direction:
		0:
			health_bar.position.y = 678
			status_label.position.y = 110
		1:
			health_bar.position.y = 80
			status_label.position.y = 110

func _exit_tree() -> void:
	if Conductor.ibeat_reached.is_connected(icon_thingy):
		Conductor.ibeat_reached.disconnect(icon_thingy)


func setup_healthbar() -> void:
	var stage: StageBG = get_tree().current_scene.get("stage")
	if stage:
		# very messy icon stuff
		if stage.has_node("player2") and stage.get_node("player2") is Character:
			health_bar.get_child(0).texture = stage.get_node("player2").health_icon
		if stage.has_node("player1") and stage.get_node("player1") is Character:
			health_bar.get_child(1).texture = stage.get_node("player1").health_icon


func update_score_text(hit_result: Note.HitResult, _is_tap: bool) -> void:
	if hit_result.player.botplay == true:
		status_label.text = "BotPlay Enabled"
		return
	status_label.text = "Score:%s" % hit_result.player.stats.score


func icon_thingy(ibeat: int) -> void:
	if ibeat % icon_bump_interval == 0:
		icon_animation.seek(0.0)
		icon_animation.play("bump")
