extends Control

@onready var back: ColorRect = $"back"
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
		var old_scroll: int = Preferences.scroll_direction
		var old_rscale: float = Preferences.receptor_size
		var old_center: bool = Preferences.centered_playfield
		var old_counter: int = Preferences.judgement_counter
		ow.close_callback = func():
			Globals.set_node_inputs(self, true)
			var scene: Node = get_tree().current_scene
			if scene.name == "gameplay":
				#region Reset Scroll Direction
				var receptors_changed: bool = (old_scroll != Preferences.scroll_direction
					or old_rscale != Preferences.receptor_size
					or old_center != Preferences.centered_playfield)
				if receptors_changed:
					for nf: NoteField in scene.note_fields:
						if old_rscale != Preferences.receptor_size:
							nf.scale = Vector2(Preferences.receptor_size, Preferences.receptor_size)
						if old_scroll != Preferences.scroll_direction:
							var whyy: float = 1.0
							match Preferences.scroll_direction:
								0: whyy = 1.0
								1: whyy = -1.0
							nf.scroll_mods.fill(Vector2(1.0, whyy))
							nf.reset_scrolls(nf.scroll_mods)
							#print_debug(nf.scroll_mods)
						if old_center != Preferences.centered_playfield:
							nf.check_centered()
						for note: Note in scene.note_cluster.note_queue:
							if is_instance_valid(note.notefield):
								var key_c: int = note.notefield.key_count
								note.reset_scroll(note.notefield.scroll_mods[note.column % key_c])
								if is_instance_valid(note.receptor) and is_instance_valid(note.object):
									note.object.scale = note.receptor.scale
				#endregion

				#region Reset HUD Positions
				if scene.get("hud") != null:
					if receptors_changed: scene.hud.reset_positions()
					if (old_counter != Preferences.judgement_counter
					and scene.hud.has_method("reset_judgement_counter")):
						scene.hud.reset_judgement_counter()
				#endregion

		add_child(ow),
	func() -> void:
		SoundBoard.stop_bgm()
		Gameplay.prev_tallies.clear()
		Globals.change_scene(load("res://scenes/menu/freeplay_menu.tscn")),
]
var current_selection: int = 0
var options_len: int = 0

func _ready() -> void:
	if get_tree().current_scene != self:
		Globals.set_node_inputs(get_tree().current_scene, false)
	options_len = $"options".get_line_count()

	back.modulate.a = 0.0
	create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE) \
	.tween_property(back, "modulate:a", 0.6, 0.4)

	setup_music()
	setup_level_label()
	update_selection()


func setup_level_label() -> void:
	if Chart.global and Chart.global.song_info:
		$"level_label".text = "Song: %s\nDifficulty: %s\nFails: %s" % [
			Chart.global.song_info.name, Chart.global.song_info.difficulty.display_name,
			"0"]


func setup_music() -> void:
	if music:
		SoundBoard.play_bgm(music, 0.0, 1.0, true)
		SoundBoard.bgm_player.seek(randf_range(0.01, music.get_length() * 0.5))
		SoundBoard.fade_bgm(0.01, 0.7, 8.0)


func _unhandled_input(_e: InputEvent) -> void:
	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	if ud: update_selection(ud)
	if Input.is_action_just_pressed("ui_accept"):
		Globals.set_node_inputs(self, false)
		options[current_selection].call()


func update_selection(new: int = 0) -> void:
	# i wanted to do something different for once @crowplexus
	current_selection = wrapi(current_selection + new, 0, options_len)
	for line: Control in $"options".get_children():
		line.modulate.a = 1.0 if line.get_index() == current_selection else 0.6
	if new != 0: SoundBoard.play_sfx(Globals.MENU_SCROLL_SFX)
