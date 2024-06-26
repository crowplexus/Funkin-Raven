extends Control

@onready var health_bar: ProgressBar = $"health_bar"
@onready var progress_label: Label = $"progress_label"
@onready var status_label: Label = $"status_label"
@onready var icon_animation: AnimationPlayer = $"health_bar/animation_player"

@export var icon_bump_interval: int = 1 # beats
@export var health_bar_icons: Array[CanvasItem] = []

var _hb_twn: Tween
var _song_name: StringName = ""


func _ready() -> void:
	reset_positions()
	health_bar.modulate.a = 0.0
	_hb_twn = create_tween().set_ease(Tween.EASE_IN).bind_node(health_bar)
	_hb_twn.tween_property(health_bar, "modulate:a", 1.0, 1.5 * Conductor.crotchet)
	if Chart.global:
		_song_name = Chart.global.song_info.name
	progress_label.visible = Preferences.show_timer
	Conductor.ibeat_reached.connect(icon_thingy)


func reset_positions() -> void:
	match Preferences.scroll_direction:
		0:
			health_bar.position.y = 645
			status_label.position.y = 680
			progress_label.position.y = 0.0
		1:
			health_bar.position.y = 80
			status_label.position.y = 115
			progress_label.position.y = 690

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
	if not health_bar_icons.is_empty():
		move_icons()
	if progress_label.visible and Conductor.time >= 0.0:
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
	progress_label.text = "%s%s / %s (%s)" % [
		"%s | " % _song_name if not _song_name.is_empty() else "",
		Globals.format_to_time(Conductor.time),
		Globals.format_to_time(Conductor.length),
		"%d%%" % [absf(Conductor.time / Conductor.length) * 100.0]
	]


func move_icons() -> void:
	for icon: CanvasItem in health_bar_icons:
		var lr_axis: int = -1 if health_bar.fill_mode == ProgressBar.FILL_BEGIN_TO_END else 1
		var icon_health: float = health_bar.value if icon.flip_h else 100 - health_bar.value
		if lr_axis == -1:
			icon_health = 100 - health_bar.value if icon.flip_h else health_bar.value
		var hb_offset: float = 0.0 if lr_axis == -1 else health_bar.size.x
		icon.frame = 1 if icon_health < 20 else 0
		icon.position.x = -(health_bar.value * health_bar.size.x / 100) + hb_offset
		icon.position.x *= lr_axis


func icon_thingy(ibeat: int) -> void:
	if ibeat % icon_bump_interval == 0:
		icon_animation.seek(0.0)
		icon_animation.play("bump")


func set_player(player: int) -> void:
	match player:
		0: health_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		1: health_bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END
