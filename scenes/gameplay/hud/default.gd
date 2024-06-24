extends Control

@onready var health_bar: = $"health_bar"
@onready var time_bar: = $"timer"
@onready var time_label: = $"timer/label"
@onready var status_label: = $"status_label"

var hb_twn: Tween
var song_name: StringName = ""


func _ready() -> void:
	match Preferences.scroll_direction:
		1:
			health_bar.position.y = 100
			status_label.position.y = 135
	health_bar.modulate.a = 0.0
	hb_twn = create_tween().set_ease(Tween.EASE_IN).bind_node(health_bar)
	hb_twn.tween_property(health_bar, "modulate:a", 1.0, 1.5 * Conductor.crotchet)
	if is_instance_valid(Chart.global):
		song_name = Chart.global.song_info.name
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
	if time_bar.visible and Conductor.time >= 0.0:
		update_time_bar()


func update_score_text(hit_result: Note.HitResult, _is_tap: bool) -> void:
	if hit_result.player.botplay == true:
		status_label.text = "BotPlay Enabled"
		return

	var text: String = hit_result.player.mk_stats_string()
	match Preferences.status_display_mode:
		1: status_label.text = text.substr(text.find("•") + 1, text.length())
		2: status_label.text = text.substr(0, text.find(" • "))
		_: status_label.text = text


func update_time_bar() -> void:
	time_bar.value = absf(Conductor.time / Conductor.length) * time_bar.max_value
	time_label.text = "%s%s / %s (%s)" % [
		"%s | " % song_name if not song_name.is_empty() else "",
		Globals.format_to_time(Conductor.time),
		Globals.format_to_time(Conductor.length),
		"%d%%" % [time_bar.value]
	]

