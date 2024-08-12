extends Node2D
class_name Gameplay

enum GameMode {
	CAMPAIGN = 0,
	FREEPLAY = 1,
	PLAYLIST = 2,
}

@export var combo_group: Control
@export var note_fields: Array[NoteField] = []
@export var skin: UISkin

@onready var countdown_timer: Timer = $"countdown_timer"
@onready var note_cluster: NoteCluster = $"ui_layer/note_cluster"
@onready var event_machine: EventMachine = $"event_machine"

static var prev_tallies: Array[Tally] = []
static var game_mode: GameMode = GameMode.FREEPLAY
static var play_list: Array[SongItem] = []
static var play_list_pos: int = 0

var countdown_beat: int = 0
var hud_beat_interval: int = 4
var default_hud_scale: Vector2 = Vector2.ONE
var modchart_pack: ModchartPack

var active_player: Player
var music_player: AudioStreamPlayer
var stage: StageBG

var update_music: bool = true

#region Built-in Functions

func _ready() -> void:
	if not Chart.global: Chart.global = Chart.load_default()
	if not skin: skin = Globals.DEFAULT_SKIN
	if combo_group and not combo_group.skin: combo_group.skin = skin
	default_hud_scale = ui_layer.scale
	if modchart_pack: modchart_pack.dispose()
	modchart_pack = ModchartPack.pack_from_folders([
		"res://assets/scripts",
		"res://assets/scripts/songs/%s" % Chart.global.song_info.folder,
	])
	modchart_pack.name = "modcharts"
	add_child(modchart_pack)
	modchart_pack.call_mod_method("_on_ready", [self])

	setup_music()
	setup_notes()
	if has_node("main_stage"):
		remove_child($"main_stage")
	load_stage()
	load_characters(Chart.global.song_info.characters)
	# HUD
	if ui_layer.has_node("hud"):
		ui_layer.remove_child(ui_layer.get_node("hud"))
	unload_current_hud()
	var hud_script: int = modchart_pack.call_mod_method("_set_hud", [self])
	match Preferences.hud_style:
		1: load_hud(Globals.DEFAULT_HUD.instantiate())
		2: load_hud(load("res://scenes/gameplay/hud/recreations/kade.tscn").instantiate())
		3: load_hud(load("res://scenes/gameplay/hud/recreations/psych.tscn").instantiate())
		4: load_hud(load("res://scenes/gameplay/hud/recreations/classic.tscn").instantiate())
		_ when hud_script != ModchartPack.CallableRequest.STOP: # Custom, per-song HUDs
			load_hud(Globals.DEFAULT_HUD.instantiate())

	if combo_group and not combo_group.judgment_sprite:
		combo_group.push_judgement()
		combo_group.push_combo(2)

	restart_countdown()

func clear_notes() -> void:
	for node: Node in note_cluster.get_children():
		note_cluster.remove_child(node)
		node.queue_free()

func switch_stage(stage_file: String = "") -> void:
	remove_child(stage)
	load_stage(stage_file)

func swap_character(player: int = 1, character: String = "") -> void:
	load_character(character, player)

func restart_countdown() -> void:
	countdown_timer.start(Conductor.crotchet)
	if not countdown_timer.timeout.is_connected(display_countdown):
		countdown_timer.timeout.connect(display_countdown)

func end_play() -> void:
	update_music = false
	# TODO: save tallies
	match game_mode:
		GameMode.CAMPAIGN, GameMode.PLAYLIST:
			if play_list_pos < play_list.size() - 1:
				for i: int in note_fields.size():
					# NOTE: broken? fix??? TODO!?!?
					var tally: = note_fields[i].player.tallies
					if prev_tallies.has(tally): prev_tallies[i] = tally
					else: prev_tallies.append(tally.duplicate())
				play_list_pos += 1
				var diff: Dictionary = play_list[play_list_pos].difficulty
				Chart.global = Chart.request(play_list[play_list_pos].folder_name, diff)
				countdown_beat = 0
				_ready()
				update_music = true
				return
			else:
				var where_to: String = "freeplay_menu"
				if game_mode == GameMode.CAMPAIGN:
					where_to = "story_menu"
				play_list_pos = 0
				prev_tallies.clear()
				play_list.clear()
				Globals.change_scene(load("res://scenes/menu/%s.tscn" % where_to))
		GameMode.FREEPLAY:
			var diff: = Chart.global.song_info.difficulty
			Highscore.register(active_player.tallies, Chart.global.song_info.folder, diff)
			Globals.change_scene(load("res://scenes/menu/freeplay_menu.tscn"))

func _process(delta: float) -> void:
	var process_script: int = modchart_pack.call_mod_method("_on_process", [self, delta])
	if process_script == ModchartPack.CallableRequest.STOP:
		return
	if update_music:
		if not music_player or (music_player and not music_player.playing):
			Conductor.update(Conductor.time + delta)
		else:
			Conductor.update(music_player.get_playback_position() + AudioServer.get_time_since_last_mix())
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

func load_stage(stage_file: String = "") -> void:
	if stage_file.is_empty():
		stage_file = Chart.global.song_info.background
	if stage: stage.queue_free()

	var stage_path: String = "res://scenes/backgrounds/mainStage.tscn"
	if ResourceLoader.exists(stage_path.replace("mainStage", stage_file)):
		stage_path = stage_path.replace("mainStage", stage_file)
	stage = load(stage_path).instantiate()
	add_child(stage)
	# move to the top
	move_child(stage, 0)

func load_characters(chars: Array[String]) -> void:
	for character: String in chars:
		var char_path: String = "res://scenes/characters/%s.tscn" % character
		if not ResourceLoader.exists(char_path):
			continue
		var idx: int = Chart.global.song_info.characters.find(character)
		var actor: Character = load_character(character, idx + 1)
		if idx < note_fields.size():
			note_fields[idx].connected_characters.clear()
			note_fields[idx].connected_characters.append(actor)

func load_character(char_name: String = "", char_position: int = 1) -> Character:
	var char_path: String = "res://scenes/characters/%s.tscn" % char_name
	if not ResourceLoader.exists(char_path):
		return
	#var idx: int = Chart.global.song_info.characters.find(character)
	var mark: = stage.get_node("player%s" % char_position)
	var actor: Character = load(char_path).instantiate()
	actor.name = "player%s" % char_position
	actor.global_position = mark.global_position

	if char_position == 1: actor._faces_left = true
	var mark_idx: int = mark.get_index()
	stage.remove_child(mark)
	mark.queue_free()
	stage.add_child(actor)
	stage.move_child(actor, mark_idx)
	return actor

func setup_music() -> void:
	if Chart.global.song_info.instrumental:
		music_player = $"music_player"
		music_player.stream.stream_count = Chart.global.song_info.vocals.size() + 1
		# create instrumental stream and stuff.
		music_player.stream.set_sync_stream(0, Chart.global.song_info.instrumental)
		for i: int in Chart.global.song_info.vocals.size():
			# set vocal tracks to sync with the instrumental.
			music_player.stream.set_sync_stream(i + 1, Chart.global.song_info.vocals[i])
		if music_player.stream.get_sync_stream(0):
			Conductor.length = music_player.stream.get_sync_stream(0).get_length()
		else:
			Conductor.length = Chart.global.notes.back().time
		if not music_player.finished.is_connected(end_play):
			music_player.finished.connect(end_play)
	Conductor.set_time(-(Conductor.crotchet) * 5)

func setup_notes() -> void:
	clear_notes()
	note_cluster.note_queue.clear()
	event_machine.event_list.clear()
	generate_fields()
	note_cluster.note_queue = Chart.global.notes.duplicate()
	event_machine.event_list = Chart.global.events.duplicate()
	event_machine._ready()
	note_cluster._ready()

#endregion

#region PlayField

func generate_fields(configs: Array[Dictionary] = Chart.global.song_info.notefields) -> void:
	for idx: int in configs.size():
		var nf: NoteField
		var data: Dictionary = configs[idx]
		var nf_exists: bool = false
		if idx < note_fields.size():
			nf = note_fields[idx]
			nf_exists = true
		else:
			nf = load("res://scenes/gameplay/notes/notefield.tscn").instantiate()
		Chart.global.song_info.configure_notefield(nf, data)
		note_cluster.connect_notefield(nf)
		if not nf_exists:
			note_fields.append(nf)
			ui_layer.add_child(nf)

	for idx: int in note_fields.size():
		var field: NoteField = note_fields[idx]
		# Setup Player
		if field.player: field.player.queue_free()
		field.player = Player.new()
		var ptally: Tally
		# use playlist tallies (if they exist)
		var reuse_tally: bool = prev_tallies.is_empty() and idx < prev_tallies.size() - 1
		if game_mode != GameMode.CAMPAIGN or GameMode.PLAYLIST:
			reuse_tally = false
		if reuse_tally:
			ptally = prev_tallies[idx]
		else:
			ptally = Tally.new()
		field.player.tallies = ptally
		field.player.notefield = field
		field.player.autoplay = true

		#region Connect Callables
		field.player.note_hit = func(note: Note) -> void:
			field.on_note_hit(note, note.hold_progress <= 0.0)
			if not field.player.autoplay:
				update_score_text(field.player.tallies, note.hold_progress <= 0.0)
				if hud and note.hit_result and "name" in note.hit_result.judgment and hud.has_method("display_ms"):
					var col: Color = Scoring.get_judgement_colour(note.hit_result.judgment.name)
					hud.call_deferred("display_ms", note.hit_result.hit_time, col)
				display_judgement(note.hit_result)
				display_combo(note.hit_result)

		field.player.note_miss = func(column: int, note: Note) -> void:
			field.on_note_miss(column, note)
			if not field.player.autoplay:
				var is_tap: bool = note and note.hold_progress <= 0.0
				update_score_text(field.player.tallies, is_tap)
				if note and note.hit_result:
					display_combo(note.hit_result)

		field.player.note_list = Chart.global.notes.filter(func(n: Note) -> bool:
			n.note_flew = func(dn: Note) -> void:
				if dn.player == field.get_index():
					field.on_note_miss(dn.column, dn)
					#field.player.tallies.apply_miss(n.column, n)
				if not field.player.autoplay and dn.hit_result:
					update_score_text(field.player.tallies, dn.hold_progress <= 0.0)
					display_combo(dn.hit_result)
			return is_same(idx, n.player))
		#endregion

		# set controls
		if is_same(idx, Preferences.playfield_side):
			for j: int in field.key_count: field.player.controls.append("note%s" % j)
			update_score_text(field.player.tallies, true)
			field.player.autoplay = false
			active_player = field.player
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
		countdown_timer.timeout.disconnect(display_countdown)
		var song_start_script: int = modchart_pack.call_mod_method("_on_song_start", [self])
		if song_start_script != ModchartPack.CallableRequest.STOP:
			if music_player and music_player.stream:
				music_player.play(0.0)
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
func update_score_text(tally: Tally, is_tap: bool = false) -> void:
	if hud: hud.update_score_text(tally, is_tap)

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
		if not custom_display: combo_group.display_combo(hit_result)

## Loads a new HUD to the screen.
func load_hud(hud_to_load: GameHUD, make_primary: bool = true, start_visible: bool = true) -> void:
	if make_primary: hud = hud_to_load
	hud.visible = start_visible
	ui_layer.add_child(hud_to_load)
	ui_layer.move_child(hud_to_load, 0)

## Gets rid of the loaded primary hud.
func unload_current_hud() -> void:
	unload_hud(hud)

## Gets rid of a specified hud that is active.
func unload_hud(hud_object: GameHUD) -> void:
	if hud_object and ui_layer.has_node(hud_object.get_path()):
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

## Func ran once every song bar.
func on_ibar_reached(ibar: int) -> void:
	var _bar_script: int = modchart_pack.call_mod_method("_on_ibar_reached", [self, ibar])
	#if bar_script == ModchartPack.CallableRequest.STOP:
	#	return

#endregion
