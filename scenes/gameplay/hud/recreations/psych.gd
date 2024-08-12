extends GameHUD

@onready var health_bar: TextureProgressBar = $"health_bar"
@onready var time_bar: ProgressBar = $"timer"
@onready var time_label: Label = $"timer/label"
@onready var status_label: Label = $"status_label"
@onready var icon_animation: AnimationPlayer = $"health_bar/animation_player"

@export var icon_bump_interval: int = 1
@export var health_bar_icons: Array[CanvasItem] = []

var _tb_twn: Tween

func _ready() -> void:
	reset_positions()
	time_bar.modulate.a = 0.0
	_tb_twn = create_tween().set_ease(Tween.EASE_IN).bind_node(health_bar)
	_tb_twn.tween_property(time_bar, "modulate:a", 1.0, 1.5 * Conductor.crotchet)
	time_bar.visible = Preferences.show_timer

	setup_healthbar()
	Conductor.ibeat_reached.connect(icon_thingy)

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

func update_score_text(tally: Tally, _is_tap: bool) -> void:
	if tally.invalid == true:
		status_label.text = "INVALID"
		return

	var acc: float = snappedf(tally.accuracy, 0.01)
	# psych rating fc
	var rating_fc: String = "Clear"
	if tally.breaks < 10:
		if tally.breaks == 0: rating_fc = Scoring.get_clear_flag(tally.hit_registry, true)
		else: rating_fc = "SDCB"

	var acc_str: String = " (%s%%) - %s" % [ acc, rating_fc ]
	var text: String = "Score: %s | Breaks: %s | Rating: %s" % [
		tally.score, tally.breaks, get_rating(acc) + acc_str]
	status_label.text = text

func update_time_bar() -> void:
	time_bar.value = absf(Conductor.time / Conductor.length) * time_bar.max_value
	time_label.text = "%s" % [ Globals.format_to_time(Conductor.length - Conductor.time) ]

func reset_positions() -> void:
	match Preferences.scroll_direction:
		0:
			health_bar.position.y = 645
			status_label.position.y = 680
			time_bar.position.y = 19
		1:
			health_bar.position.y = 80
			status_label.position.y = 115
			time_bar.position.y = size.y - 34

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

func format_to_time(value: float) -> String:
	var minutes: float = Globals.float_to_minute(value)
	var seconds: float = Globals.float_to_seconds(value)
	var formatter: String = "%2d:%02d" % [minutes, seconds]
	var hours: int = Globals.float_to_hours(value)
	if hours != 0: # append hours if needed
		formatter = ("%2d:%02d:02d" % [hours, minutes, seconds])
	return formatter
