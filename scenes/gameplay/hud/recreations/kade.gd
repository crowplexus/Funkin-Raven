extends GameHUD

@onready var health_bar: TextureProgressBar = $"health_bar"
@onready var time_bar: TextureProgressBar = $"timer"
@onready var time_label: Label = $"timer/label"
@onready var status_label: Label = $"status_label"
@onready var icon_animation: AnimationPlayer = $"health_bar/animation_player"
@onready var judge_counter: Label = $"judge_counter"

@export var icon_bump_interval: int = 1
@export var health_bar_icons: Array[CanvasItem] = []

var _song_name: StringName = ""

func _ready() -> void:
	reset_positions()
	if Chart.global:
		_song_name = Chart.global.song_info.name
	$"watermark".text = "%s - FR v%s" % [ _song_name, Globals.ENGINE_VERSION ]
	time_bar.visible = Preferences.show_timer
	time_label.text = _song_name
	time_bar.value = 0.0

	setup_healthbar()
	reset_judgement_counter()
	Conductor.ibeat_reached.connect(icon_thingy)

func reset_judgement_counter() -> void:
	judge_counter.visible = Preferences.judgement_counter != 0
	if judge_counter.visible:
		match Preferences.judgement_counter:
			1:
				judge_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				judge_counter.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE)
			2:
				judge_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				judge_counter.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_KEEP_SIZE)

func _process(_delta: float) -> void:
	if not health_bar_icons.is_empty():
		move_icons()
	if time_bar.visible and Conductor.time >= 0.0:
		update_time_bar()

func _exit_tree() -> void:
	if Conductor.ibeat_reached.is_connected(icon_thingy):
		Conductor.ibeat_reached.disconnect(icon_thingy)

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

func icon_thingy(ibeat: int) -> void:
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
			time_bar.position.y = 5
			health_bar.position.y = 645
			status_label.position.y = 704
		1:
			health_bar.position.y = 90
			status_label.position.y = 140
			time_bar.position.y = size.y * 0.96

func update_score_text(tally: Tally, _is_tap: bool) -> void:
	if tally.invalid == true:
		status_label.text = "INVALID"
		return

	var clear_flag: String = "Clear"
	if tally.breaks < 10:
		if tally.breaks == 0: clear_flag = Scoring.get_clear_flag(tally.hit_registry, true)
		else: clear_flag = "SDCB"

	var grade_str: String = "("+clear_flag+") "
	var acc: float = snappedf(tally.accuracy, 0.01)
	grade_str += get_ke_grade(acc)

	var text: String = "Score:%s | Combo Breaks:%s | Accuracy:%s%%" % [
		tally.score, tally.breaks, str(acc),]
	text += " | %s" % grade_str
	status_label.text = text
	if judge_counter and judge_counter.visible:
		judge_counter.text = get_judge_counter_text(tally.hit_registry)
		judge_counter.text += "\n%s: %s" % [ format_judge("miss"), tally.misses ]

func get_judge_counter_text(hit_reg: Dictionary) -> String:
	var counter: String = ""
	for i: int in hit_reg.keys().size():
		var key: String = hit_reg.keys()[i]
		if key == "perfect":
			continue
		if not counter.is_empty(): counter += "\n"
		counter += "%s: %s" % [format_judge(key.to_lower()), hit_reg[key]]
	return counter

func update_time_bar() -> void:
	time_bar.value = absf(Conductor.time/Conductor.length)*time_bar.max_value

func get_ke_grade(acc: float):
	match acc: # "use a for loop" this is literally faster and easier readable please st
		_ when acc >= 99.9935: return "AAAAA"
		_ when acc >= 99.980: return "AAAA:"
		_ when acc >= 99.970: return "AAAA."
		_ when acc >= 99.955: return "AAAA"
		_ when acc == 99.90: return "AAA:"
		_ when acc >= 99.80: return "AAA."
		_ when acc >= 99.70: return "AAA"
		_ when acc >= 99.0: return "AA:"
		_ when acc >= 96.50: return "AA."
		_ when acc >= 93.0: return "AA"
		_ when acc >= 90.0: return "A:"
		_ when acc >= 85.0: return "A."
		_ when acc >= 80.0: return "A"
		_ when acc >= 70.0: return "B"
		_ when acc >= 61.0: return "C"
		_ when acc < 60.0: return "D"
		_: return "N/A"

func format_judge(j: String) -> StringName:
	match j.to_lower():
		"epic": return "Epics"
		"sick": return "Sicks"
		"good": return "Goods"
		"bad": return "Bads"
		"shit": return "Shits"
		"miss": return "Misses"
		"break": return "Combo Breaks"
		_: return "???"
