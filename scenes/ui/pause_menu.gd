extends Control

@onready var back: ColorRect = $"back"
@onready var options_sprite: Alphabet = $"options"
@onready var level_label: Label = $"level_label"

@export var music: AudioStream = preload("res://assets/audio/bgm/breakfast.ogg")

var options: Array[Callable] = [
	func() -> void:
		get_tree().paused = false
		if get_tree().current_scene != self:
			Globals.set_node_inputs(get_tree().current_scene, true)
		SoundBoard.stop_bgm()
		queue_free(),
	func() -> void:
		get_tree().paused = false
		SoundBoard.stop_bgm()
		get_tree().reload_current_scene(),
	func() -> void:
		var ow: Control = Globals.OPTIONS_WINDOW.instantiate()
		Globals.set_node_inputs(self, false)
		ow.close_callback = func():
			Globals.set_node_inputs(self, true)
		add_child(ow),
	func() -> void:
		SoundBoard.stop_bgm()
		Globals.change_scene(load("res://scenes/menu/freeplay_menu.tscn")),
]
var current_selection: int = 0

func _ready() -> void:
	if get_tree().current_scene != self:
		Globals.set_node_inputs(get_tree().current_scene, false)
	back.modulate.a = 0.0
	create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE) \
	.tween_property(back, "modulate:a", 0.6, 0.4)
	if is_instance_valid(music):
		SoundBoard.play_bgm(music, 0.0, 1.0, true)
		SoundBoard.bgm_player.seek(randf_range(0.01, music.get_length() * 0.5))
		SoundBoard.fade_bgm(0.01, 0.7, 8.0)

	if Chart.global and Chart.global.song_info and Conductor.time >= 0.0:
		level_label.text = "Song: %s\nDifficulty:%s\nFails: %s" % [
			Chart.global.song_info.name, Chart.global.song_info.difficulty.display_name,
			"0"]
	update_selection()


func _unhandled_input(_e: InputEvent) -> void:
	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	if ud: update_selection(ud)
	if Input.is_action_just_pressed("ui_accept"):
		Globals.set_node_inputs(self, false)
		options[current_selection].call()


func update_selection(new: int = 0) -> void:
	# i wanted to do something different for once @crowplexus
	current_selection = wrapi(current_selection + new, 0, options_sprite.get_child_count())
	for line: Control in options_sprite.get_children():
		line.modulate.a = 1.0 if line.get_index() == current_selection else 0.6
	if new != 0: SoundBoard.play_sfx(Globals.MENU_SCROLL_SFX)
