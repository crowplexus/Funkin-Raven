extends Control

@onready var health_bar: TextureProgressBar = $"health_bar"
@onready var time_bar: ProgressBar = $"timer"
@onready var time_label: Label = $"timer/label"
@onready var status_label: Label = $"status_label"
@onready var icon_animation: AnimationPlayer = $"health_bar/animation_player"

@export var icon_bump_interval: int = 1 # beats

var _hb_twn: Tween
var _song_name: StringName = ""


func _ready() -> void:
	reset_positions()
	health_bar.modulate.a = 0.0
	_hb_twn = create_tween().set_ease(Tween.EASE_IN).bind_node(health_bar)
	_hb_twn.tween_property(health_bar, "modulate:a", 1.0, 1.5 * Conductor.crotchet)
	if Chart.global:
		_song_name = Chart.global.song_info.name
	time_bar.visible = Preferences.show_timer
	Conductor.ibeat_reached.connect(icon_thingy)


func reset_positions() -> void:
	match Preferences.scroll_direction:
		0:
			health_bar.position.y = 645
			status_label.position.y = 680
		1:
			health_bar.position.y = 100
			status_label.position.y = 135

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


func _process(_delta: float) -> void:
	if time_bar.visible and Conductor.time >= 0.0:
		update_time_bar()


func update_score_text(hit_result: Note.HitResult, _is_tap: bool) -> void:
	if hit_result.player.botplay == true:
		status_label.text = "BotPlay Enabled"
		return

	var text: String = str(hit_result.player.stats)
	match Preferences.status_display_mode:
		1: status_label.text = text.substr(text.find("•") + 1, text.length())
		2: status_label.text = text.substr(0, text.find(" • "))
		_: status_label.text = text


func update_time_bar() -> void:
	time_bar.value = absf(Conductor.time / Conductor.length) * time_bar.max_value
	time_label.text = "%s%s / %s (%s)" % [
		"%s | " % _song_name if not _song_name.is_empty() else "",
		Globals.format_to_time(Conductor.time),
		Globals.format_to_time(Conductor.length),
		"%d%%" % [time_bar.value]
	]


func icon_thingy(ibeat: int) -> void:
	if ibeat % icon_bump_interval == 0:
		icon_animation.seek(0.0)
		icon_animation.play("bump")
