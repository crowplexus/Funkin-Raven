extends Control

@onready var health_bar: = $"health_bar"
@onready var time_bar: = $"timer"
@onready var time_label: = $"timer/label"
@onready var status_label: = $"status_label"

var kade_grades: Array = [
	# psych engine looking array
	[	99.9935,	"AAAAA"	],
	[	99.980,		"AAAA:"	],
	[	99.970,		"AAAA."	],
	[	99.955,		"AAAA"	],
	[	99.90,		"AAA:"	],
	[	99.80,		"AAA."	],
	[	99.70,		"AAA"	],
	[	99.0,		"AA:"	],
	[	96.50,		"AA."	],
	[	93.0,		"AA"	],
	[	90.0,		"A:"	],
	[	85.0,		"A."	],
	[	80.0,		"A"		],
	[	70.0,		"B"		],
	[	60.0,		"C"		],
	[	59.0,		"D"		],
]

var song_name: StringName = ""


func _ready() -> void:
	match Preferences.scroll_direction:
		1:
			health_bar.position.y = 90
			status_label.position.y = 140
			time_bar.position.y = get_viewport_rect().size.y * 0.96

	if is_instance_valid(Chart.global):
		song_name = Chart.global.song_info.name
	$"watermark".text = "%s - FR v%s" % [ song_name, Globals.ENGINE_VERSION ]
	time_bar.visible = Preferences.show_timer
	time_label.text = song_name
	time_bar.value = 0.0


func setup_healthbar() -> void:
	var stage: StageBG = get_tree().current_scene.get("stage")
	if is_instance_valid(stage):
		# very messy icon stuff
		if stage.has_node("player2") and stage.get_node("player2") is Character:
			health_bar.get_child(0).texture = stage.get_node("player2").health_icon
		if stage.has_node("player1") and stage.get_node("player1") is Character:
			health_bar.get_child(1).texture = stage.get_node("player1").health_icon


func _process(_delta: float) -> void:
	if Conductor.active:
		update_time_bar()


func update_score_text(hit_result: Note.HitResult, _is_tap: bool) -> void:
	if hit_result.player.botplay == true:
		status_label.text = "BotPlay Enabled"
		return

	var grade: String = Scoring.get_clear_flag(hit_result.player.jhit_regis)
	var grade_str: String = "(Clear) " if grade.is_empty() else "("+grade+") "
	grade_str += get_ke_grade(snappedf(hit_result.player.accuracy, 0.01))

	var text: String = "Score: %s | Combo Breaks: %s | Accuracy: %s%%" % [
		hit_result.player.score, hit_result.player.misses + hit_result.player.breaks,
		str(snappedf(hit_result.player.accuracy, 0.01)),
	]
	text += " | %s" % grade_str
	match Preferences.status_display_mode:
		1: status_label.text = text.substr(text.find("|") + 1, text.length())
		2: status_label.text = text.substr(0, text.find(" | "))
		_: status_label.text = text


func update_time_bar() -> void:
	if time_bar.visible and Conductor.time >= 0.0:
		time_bar.value = absf(Conductor.time / Conductor.length) * time_bar.max_value


func get_ke_grade(acc: float) -> String:
	for g: Array in kade_grades:
		if acc >= g[0]:
			return g[1]
	return "N/A"
