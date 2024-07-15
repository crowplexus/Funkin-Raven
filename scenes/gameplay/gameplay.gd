extends Node2D

@export var note_fields: Array[NoteField] = []
@export var skin: UISkin = preload("res://assets/sprites/ui/normal.tres")

@onready var countdown_timer: Timer = $"countdown_timer"
@onready var note_cluster: NoteCluster = $"ui_layer/note_cluster"
@onready var event_machine: EventMachine = $"event_machine"
@onready var combo_group: Control = $"ui_layer/combo_group"

var countdown_beat: int = 0
var hud_beat_interval: int = 4
var default_hud_scale: Vector2 = Vector2.ONE
var modchart_pack: ModchartPack

var music: AudioStreamPlayer
var stage: StageBG

#region Built-in Functions

func _ready() -> void:
	if not Chart.global:
		Chart.global = Chart.request("test", SongItem.DEFAULT_DIFFICULTY_SET.hard)

	#region Setup Music
	Conductor.set_time(-(Conductor.crotchet) * 5)

	if Chart.global.song_info.instrumental:
		music = $"music_player"
		for vocal_stream: AudioStream in Chart.global.song_info.vocals:
			var vocal_track: AudioStreamPlayer = music.duplicate()
			vocal_track.stream = vocal_stream
			music.add_child(vocal_track)
		music.stream = Chart.global.song_info.instrumental.duplicate()
		if music and music.stream:
			Conductor.length = music.stream.get_length()
		else:
			Conductor.length = Chart.global.notes.back().time
	#endregion

	default_hud_scale = ui_layer.scale
	modchart_pack = ModchartPack.pack_from_folders([
		"res://assets/scripts",
		"res://assets/scripts/songs/%s" % Chart.global.song_info.folder,
	])
	modchart_pack.name = "modcharts"
	add_child(modchart_pack)
	modchart_pack.call_mod_method("_on_ready", [self])

	#region Setup Notes
	generate_fields()
	note_cluster.note_queue = Chart.global.notes.duplicate()
	event_machine.event_list = Chart.global.events.duplicate()
	event_machine._ready()
	note_cluster._ready()
	#endregion

	#region Setup Stage
	remove_child($"main_stage")
	ui_layer.remove_child(ui_layer.get_node("hud"))
	# HUD
	var hud_script: int = modchart_pack.call_mod_method("_set_hud", [self])
	match Preferences.hud_style:
		1: load_hud(Globals.DEFAULT_HUD.instantiate())
		2: load_hud(load("res://scenes/gameplay/hud/recreations/kade.tscn").instantiate())
		3: load_hud(load("res://scenes/gameplay/hud/recreations/psych.tscn").instantiate())
		4: load_hud(load("res://scenes/gameplay/hud/recreations/classic.tscn").instantiate())
		_ when hud_script != ModchartPack.CallableRequest.STOP: # Custom, per-song HUDs
			load_hud(Globals.DEFAULT_HUD.instantiate())

	if combo_group:
		combo_group.skin = skin
		combo_group.push_judgement()
		combo_group.push_combo(2)

	load_stage()
	load_characters()
	#endregion

	restart_countdown()

func restart_countdown() -> void:
	countdown_timer.start(Conductor.crotchet)
	countdown_timer.timeout.connect(display_countdown)

func _process(delta: float) -> void:
	var process_script: int = modchart_pack.call_mod_method("_on_process", [self, delta])
	if process_script == ModchartPack.CallableRequest.STOP:
		return
	if not music.playing or not music:
		Conductor.update(Conductor.time + delta)
	else:
		Conductor.update(music.get_playback_position() + AudioServer.get_time_since_last_mix())
	if ui_layer.scale != default_hud_scale:
		ui_layer.scale = Vector2(
			lerpf(default_hud_scale.x, ui_layer.scale.x, exp(-delta * 5)),
			lerpf(default_hud_scale.y, ui_layer.scale.y, exp(-delta * 5))
		)
		center_ui_layer()
	modchart_pack.call_mod_method("_post_process", [self, delta])

func _unhandled_input(e: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_pause"):
		var pause_script: int = modchart_pack.call_mod_method("_on_pause", [self, e])
		if pause_script != ModchartPack.CallableRequest.STOP:
			var pause_menu: Control = load("res://scenes/ui/pause/pause_menu.tscn").instantiate()
			pause_menu.z_index = 100
			get_tree().paused = true
			ui_layer.add_child(pause_menu)

func _exit_tree() -> void:
	var exit_script: int = modchart_pack.call_mod_method("_on_exit_tree", [self])
	if exit_script == ModchartPack.CallableRequest.STOP:
		return
	if Conductor.istep_reached.is_connected(on_istep_reached):
		Conductor.istep_reached.disconnect(on_istep_reached)
	if Conductor.ibeat_reached.is_connected(on_ibeat_reached):
		Conductor.ibeat_reached.disconnect(on_ibeat_reached)
	if Conductor.ibar_reached.is_connected(on_ibar_reached):
		Conductor.ibar_reached.disconnect(on_ibar_reached)
	Conductor.reset()

#endregion

#region Loading Functions

func load_stage() -> void:
	var stage_path: String = "res://scenes/backgrounds/mainStage.tscn"
	if ResourceLoader.exists(stage_path.replace("mainStage", Chart.global.song_info.background)):
		stage_path = stage_path.replace("mainStage", Chart.global.song_info.background)
	stage = load(stage_path).instantiate()
	add_child(stage)
	# move to the top
	move_child(stage, 0)

func load_characters() -> void:
	for character: String in Chart.global.song_info.characters:
		var char_path: String = "res://scenes/characters/%s.tscn" % character
		if not ResourceLoader.exists(char_path):
			continue
		var idx: int = Chart.global.song_info.characters.find(character)
		var mark: = stage.get_node("player%s" % (idx + 1))
		var mark_idx: int = mark.get_index()

		var actor: Character = load(char_path).instantiate()
		actor.global_position = mark.global_position
		actor.name = "player%s" % str(idx + 1)
		if idx == 0: actor._faces_left = true

		stage.remove_child(mark)
		stage.add_child(actor)
		stage.move_child(actor, mark_idx)
		if idx < note_fields.size():
			note_fields[idx].connected_characters.append(actor)

#endregion

#region PlayField

func generate_fields(configs: Array[Dictionary] = Chart.global.song_info.notefields) -> void:
	for idx: int in configs.size():
		var nf: NoteField
		var data: Dictionary = configs[idx]
		if idx < note_fields.size():
			nf = note_fields[idx]
		else:
			nf = load("res://scenes/gameplay/notes/notefield.tscn").instantiate()
		Chart.global.song_info.configure_notefield(nf, data)
		note_cluster.connect_notefield(nf)
		if not note_fields.has(nf):
			note_fields.append(nf)
			ui_layer.add_child(nf)

	for idx: int in note_fields.size():
		var field: NoteField = note_fields[idx]
		# Setup Player
		field.player = Player.new()
		field.player.stats = PlayerStats.new()
		field.player.notefield = field
		field.player.autoplay = true

		#region Connect Callables
		field.player.note_hit = func(note: Note) -> void:
			field.on_note_hit(note, note.hold_progress <= 0.0)
			if not field.player.autoplay:
				update_score_text(note, note.hold_progress <= 0.0)
				display_judgement(note.hit_result)
				display_combo(note.hit_result)

		field.player.note_miss = func(_column: int, note: Note) -> void:
			if not field.player.autoplay and note and note.hit_result:
				update_score_text(note, note.hold_progress <= 0.0)
				display_combo(note.hit_result)

		field.player.note_list = Chart.global.notes.filter(func(n: Note) -> bool:
			n.note_flew = func(dn: Note) -> void:
				if not field.player.autoplay and dn.hit_result:
					update_score_text(dn, dn.hold_progress <= 0.0)
					display_combo(dn.hit_result)
			return is_same(idx, n.player))
		#endregion

		# set controls
		if is_same(idx, Preferences.playfield_side):
			for j: int in field.key_count: field.player.controls.append("note%s" % j)
			field.player.autoplay = false
		field.add_child(field.player)
		# Reset Scroll Direction
		field.reset_receptors()
		field.check_centered()
		field.reset_scrolls()

#endregion

#region User Interface

@onready var ui_layer: CanvasLayer = $"ui_layer"
## Primary loaded HUD, one that takes priority over all.
var hud: GameHUD

## Centers the HUD elements to the screen, used when the HUD zooms in.[br]
## author: swordcube
func center_ui_layer() -> void:
	ui_layer.offset = Vector2(
		(get_viewport_rect().size.x * -0.5) * (ui_layer.scale.x - 1.0),
		(get_viewport_rect().size.y * -0.5) * (ui_layer.scale.y - 1.0)
	)

func display_countdown() -> void:
	var countdown_script: int = modchart_pack.call_mod_method("_on_countdown", [self, countdown_beat])
	if countdown_script == ModchartPack.CallableRequest.STOP:
		return

	if countdown_beat > 3: # finish
		music.play(0.0)
		countdown_timer.timeout.disconnect(display_countdown)
		for track: AudioStreamPlayer in music.get_children():
			track.play(0.0)
		countdown_beat = 0
		return

	# Show the countdown sprite.
	if not skin:
		countdown_beat += 1
		return

	if countdown_beat < skin.countdown_sprites.size():
		var countdown_spr: = Sprite2D.new()
		countdown_spr.texture = skin.countdown_sprites[countdown_beat]
		countdown_spr.scale = skin.countdown_sprite_scale * 1.08
		countdown_spr.texture_filter = skin.countdown_sprite_filter
		countdown_spr.position = hud.size * 0.5
		ui_layer.add_child(countdown_spr)

		create_tween().set_ease(Tween.EASE_IN_OUT).bind_node(countdown_spr) \
		.tween_property(countdown_spr, "scale", skin.countdown_sprite_scale, Conductor.crotchet * 0.2)

		create_tween().set_ease(Tween.EASE_IN_OUT).bind_node(countdown_spr) \
		.tween_property(countdown_spr, "modulate:a", 0.0, Conductor.crotchet).set_delay(0.05) \
		.finished.connect(countdown_spr.queue_free)
	# Play the countdown sound.
	if countdown_beat < skin.countdown_sounds.size():
		SoundBoard.play_sfx(skin.countdown_sounds[countdown_beat])

	countdown_beat += 1

## Updates the Score Text in the HUD
func update_score_text(note: Note, is_tap: bool = false) -> void:
	if hud: hud.update_score_text(note, is_tap)

## Displays a Judgement on-screen as a sprite.
func display_judgement(hit_result: Note.HitResult) -> void:
	if not hit_result or not hit_result.judgment or hit_result.judgment.is_empty() \
		or hit_result.judgment.visible == false:
		return
	if combo_group:
		var custom_display = hud.call_deferred("display_judgement", hit_result, combo_group)
		if not custom_display:
			combo_group.display_judgement(hit_result)

## Display a player's combo as number sprites.
func display_combo(hit_result: Note.HitResult) -> void:
	if not hit_result:
		return
	if combo_group:
		var custom_display = hud.call_deferred("display_combo", hit_result, combo_group)
		if not custom_display:
			combo_group.display_combo(hit_result)

## Loads a new HUD to the screen.
func load_hud(hud_to_load: GameHUD, make_primary: bool = true, start_visible: bool = true) -> void:
	if make_primary: hud = hud_to_load
	hud.visible = start_visible
	ui_layer.add_child(hud_to_load)

## Gets rid of the loaded primary hud.
func unload_current_hud() -> void:
	unload_hud(hud)

## Gets rid of a specified hud that is active.
func unload_hud(hud_object: GameHUD) -> void:
	if ui_layer.has_node(hud_object.get_path()):
		ui_layer.remove_child(hud_object)
		hud_object.queue_free()

#endregion

#region Music Sync

## Func ran once every a song step.
func on_istep_reached(istep: int) -> void:
	var _step_script: int = modchart_pack.call_mod_method("_on_istep_reached", [self, istep])
	#if step_script == ModchartPack.CallableRequest.STOP:
	#	return

func on_ibeat_reached(ibeat: int) -> void:
	if ibeat < 0:
		return

	var beat_script: int = modchart_pack.call_mod_method("_on_ibeat_reached", [self, ibeat])
	if beat_script != ModchartPack.CallableRequest.STOP:
		if ibeat % hud_beat_interval == 0:
			ui_layer.scale += Vector2(0.03, 0.03)
		if music and music.get_child_count() != 0:
			for track: AudioStreamPlayer in music.get_children():
				if (music.get_playback_position() - track.get_playback_position()) > 0.01:
					resync_vocals()

## Func ran once every song bar.
func on_ibar_reached(ibar: int) -> void:
	var _bar_script: int = modchart_pack.call_mod_method("_on_ibar_reached", [self, ibar])
	#if bar_script == ModchartPack.CallableRequest.STOP:
	#	return

# temporary until godot 4.3
## Resyncs the vocals to music time.
func resync_vocals() -> void:
	if not music:
		return
	for track: AudioStreamPlayer in music.get_children():
		track.seek(music.get_playback_position() + AudioServer.get_time_since_last_mix())

#endregion
