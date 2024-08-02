extends GameHUD

@onready var health_bar: ProgressBar = $"health_bar"
@onready var progress_label: Label = $"progress_label"
@onready var status_label: Label = $"status_label"
@onready var icon_animation: AnimationPlayer = $"health_bar/animation_player"
@onready var judge_counter: Label = $"judge_counter"

@export var icon_bump_interval: int = 1 # beats
@export var health_bar_icons: Array[CanvasItem] = []

var _hb_twn: Tween
var _song_name: StringName = ""

#region Built-in functions

func _ready() -> void:
	reset_positions()
	health_bar.modulate.a = 0.0
	_hb_twn = create_tween().set_ease(Tween.EASE_IN).bind_node(health_bar)
	_hb_twn.tween_property(health_bar, "modulate:a", 1.0, 1.5 * Conductor.crotchet)
	if Chart.global and Chart.global.song_info:
		_song_name = Chart.global.song_info.name

	progress_label.visible = Preferences.show_timer
	reset_judgement_counter()
	Conductor.ibeat_reached.connect(icon_bump)

func reset_judgement_counter() -> void:
	judge_counter.visible = Preferences.judgement_counter != 0
	if judge_counter.visible:
		match Preferences.judgement_counter:
			1:
				judge_counter.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE)
				judge_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				judge_counter.position.x += 5
			2:
				judge_counter.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
				judge_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				judge_counter.position.x -= 5

func _process(_delta: float) -> void:
	if not health_bar_icons.is_empty():
		move_icons()
	if progress_label.visible and Conductor.time >= 0.0:
		update_time_bar()

func _exit_tree() -> void:
	if Conductor.ibeat_reached.is_connected(icon_bump):
		Conductor.ibeat_reached.disconnect(icon_bump)

#endregion

#region Health and Icons

func setup_healthbar() -> void:
	var stage: StageBG = get_tree().current_scene.get("stage")
	if stage:
		# very messy icon stuff
		var char_icons: Array[HealthIcon] = [null, null]
		if stage.has_node("player2") and stage.get_node("player2") is Character:
			char_icons[0] = stage.get_node("player2").health_icon
		if stage.has_node("player1") and stage.get_node("player1") is Character:
			char_icons[1] = stage.get_node("player1").health_icon
		set_icons(char_icons)

func get_health(next: float, current: float, delta: float) -> float:
	return lerpf(current, next, exp(-delta * 128))

func set_icons(icons: Array[HealthIcon]) -> void:
	for i: int in health_bar_icons.size():
		var ico: Sprite2D = health_bar_icons[i]
		if is_instance_valid(icons[i]):
			ico.texture = icons[i].texture
			ico.texture_filter = icons[i].filter
			ico.hframes = icons[i].hframes
			ico.vframes = icons[i].vframes
			ico.scale = icons[i].scale

func move_icons() -> void:
	for icon: CanvasItem in health_bar_icons:
		var lr_axis: int = -1 if health_bar.fill_mode == ProgressBar.FILL_BEGIN_TO_END else 1
		var icon_health: float = health_bar.value if icon.flip_h else 100 - health_bar.value
		if lr_axis == -1:
			icon_health = 100 - health_bar.value if icon.flip_h else health_bar.value
		var hb_offset: float = 0.0 if lr_axis == -1 else health_bar.size.x
		icon.frame = 1 if icon_health < 20 and icon.hframes == 2 else 0
		icon.position.x = -(health_bar.value * health_bar.size.x / 100) + hb_offset
		icon.position.x *= lr_axis

func icon_bump(ibeat: int) -> void:
	if ibeat % icon_bump_interval == 0:
		icon_animation.seek(0.0)
		icon_animation.play("bump")

func set_player(player: int) -> void:
	match player:
		0: health_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		1: health_bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END

#endregion

func reset_positions() -> void:
	match Preferences.scroll_direction:
		0:
			health_bar.position.y = 645
			status_label.position.y = 685
			progress_label.position.y = 0.0
		1:
			health_bar.position.y = 80
			status_label.position.y = 120
			progress_label.position.y = 690

func update_score_text(note: Note, _is_tap: bool) -> void:
	if not note:
		return
	if note.hit_result.player.autoplay == true:
		status_label.text = "AutoPlay Enabled"
		return
	status_label.text = str(note.hit_result.player.tallies)
	if judge_counter and judge_counter.visible:
		judge_counter.text = note.hit_result.player.tallies.hit_registry_string()

func update_time_bar() -> void:
	progress_label.text = "%s / %s (%s)" % [
		Globals.format_to_time(Conductor.time),
		Globals.format_to_time(Conductor.length),
		"%d%%" % [absf(Conductor.time / Conductor.length) * 100.0]
	]
