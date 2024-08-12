extends GameHUD

@onready var health_bar: ProgressBar = $"health_bar"
@onready var progress_bar: ProgressBar = $"progress_bar"
@onready var progress_label: Label = $"progress_bar/progress_label"
@onready var status_label: Label = $"health_bar/status_label"
@onready var icon_animation: AnimationPlayer = $"health_bar/animation_player"
@onready var judge_counter: Label = $"judge_counter"
@onready var ms_label: Label = $"millisecond_label"

@export var icon_bump_interval: int = 1 # beats
@export var health_bar_icons: Array[CanvasItem] = []

var _song_name: StringName = ""
var _ms_pos: Vector2 = Vector2.ZERO
var _ms_twn: Tween

#region Built-in functions

func _ready() -> void:
	if Chart.global and Chart.global.song_info:
		_song_name = Chart.global.song_info.name
	_ms_pos = ms_label.position
	progress_bar.visible = Preferences.show_timer
	Conductor.ibeat_reached.connect(icon_bump)

	setup_healthbar()
	reset_judgement_counter()
	reset_positions()
	display_ms()

func reset_judgement_counter() -> void:
	judge_counter.visible = Preferences.judgement_counter != 0
	if judge_counter.visible:
		match Preferences.judgement_counter:
			1:
				judge_counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
				#judge_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				judge_counter.position += Vector2(16, 16)
			2:
				judge_counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
				#judge_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				judge_counter.position += Vector2(16, 16)

func _process(_delta: float) -> void:
	if not health_bar_icons.is_empty():
		move_icons()
	if progress_bar.visible and Conductor.time >= 0.0:
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
			health_bar.position.y = 635
			progress_bar.position.y = 655
			ms_label.position.y = 8.0
			_ms_pos.y = 8.0
		1:
			health_bar.position.y = 80
			progress_bar.position.y = 100
			ms_label.position.y = 680
			_ms_pos.y = 680

func update_score_text(tally: Tally, _is_tap: bool) -> void:
	if tally.invalid == true:
		status_label.text = "[INVALID TALLY]"
		return

	# crazy frog.
	var cf: String = ""
	if tally.breaks < 10:
		if tally.breaks > 0: cf = "MF" if tally.breaks == 1 else "SDCB"
		else: cf = Scoring.get_clear_flag(tally.hit_registry)
	if not cf.is_empty():
		cf = " (%s)" % cf

	status_label.text = "%s - Breaks:%s - Score:%s" % [
		str(snappedf(tally.accuracy, 0.01)) + "%" + cf,
		tally.breaks, Globals.thousands_sep(tally.score)]

	if judge_counter and judge_counter.visible:
		judge_counter.text = tally.hit_registry_string() + "\n"

func display_ms(ms: float = 0.0, colour: Color = Color.WHITE) -> void:
	if _ms_twn: _ms_twn.kill()
	ms_label.position = _ms_pos
	match Preferences.scroll_direction:
		0: ms_label.position.y -= 10
		1: ms_label.position.y += 10
	ms_label.modulate = colour
	ms_label.text = str(snappedf(ms, 0.001)) + "ms"
	ms_label.show()
	_ms_twn = create_tween().bind_node(ms_label).set_parallel(true)
	_ms_twn.tween_property(ms_label, "position:y", _ms_pos.y, 0.1)
	_ms_twn.tween_property(ms_label, "modulate:a", 0.0, 0.5) \
	.set_delay(Conductor.semiquaver * 0.8)
	_ms_twn.finished.connect(ms_label.hide)


func update_time_bar() -> void:
	progress_bar.value = absf(Conductor.time / Conductor.length) * progress_bar.max_value
	progress_label.text = "%s / %s (%s)" % [
		Globals.format_to_time(Conductor.time), Globals.format_to_time(Conductor.length),
		"%d%%" % [absf(Conductor.time / Conductor.length) * progress_bar.max_value]
	]
