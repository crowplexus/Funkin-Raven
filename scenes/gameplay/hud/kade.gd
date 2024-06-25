extends Control

@onready var health_bar: TextureProgressBar = $"health_bar"
@onready var time_bar: TextureProgressBar = $"timer"
@onready var time_label: Label = $"timer/label"
@onready var status_label: Label = $"status_label"
@onready var icon_animation: AnimationPlayer = $"health_bar/animation_player"

@export var icon_bump_interval: int = 1
var _song_name: StringName = ""


func _ready() -> void:
	match Preferences.scroll_direction:
		1:
			health_bar.position.y = 90
			status_label.position.y = 140
			time_bar.position.y = get_viewport_rect().size.y * 0.96

	if is_instance_valid(Chart.global):
		_song_name = Chart.global.song_info.name
	$"watermark".text = "%s - FR v%s" % [ _song_name, Globals.ENGINE_VERSION ]
	time_bar.visible = Preferences.show_timer
	time_label.text = _song_name
	time_bar.value = 0.0
	Conductor.ibeat_reached.connect(icon_thingy)


func _exit_tree() -> void:
	if Conductor.ibeat_reached.is_connected(icon_thingy):
		Conductor.ibeat_reached.disconnect(icon_thingy)


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
		status_label.text = "BOTPLAY"
		return

	var grade: String = Scoring.get_clear_flag(hit_result.player.stats.hit_registry)
	var ke_cbs: int = hit_result.player.stats.misses + hit_result.player.stats.breaks
	if ke_cbs > 0 and ke_cbs < 10:
		grade = "SDCB"
	elif ke_cbs >= 10:
		grade = "Clear"

	var grade_str: String = "("+grade+") "
	grade_str += get_ke_grade(snappedf(hit_result.player.stats.accuracy, 0.01))

	var text: String = "Score: %s | Combo Breaks: %s | Accuracy: %s%%" % [
		hit_result.player.stats.score, ke_cbs,
		str(snappedf(hit_result.player.stats.accuracy, 0.01)),
	]
	text += " | %s" % grade_str
	match Preferences.status_display_mode:
		1: status_label.text = text.substr(text.find("|") + 1, text.length())
		2: status_label.text = text.substr(0, text.find(" | "))
		_: status_label.text = text


func update_time_bar() -> void:
	time_bar.value = absf(Conductor.time / Conductor.length) * time_bar.max_value


func icon_thingy(ibeat: int) -> void:
	if ibeat % icon_bump_interval == 0:
		icon_animation.seek(0.0)
		icon_animation.play("bump")


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
