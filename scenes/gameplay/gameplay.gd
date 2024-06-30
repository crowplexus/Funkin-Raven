extends Node2D

#region Scene Nodes

@onready var ui_layer: CanvasLayer = $"hud"
@onready var combo_group: Control = $"hud/combo_group"
@onready var note_cluster: Node2D = $"hud/note_cluster"
@onready var event_mach: EventMachine = $"event_machine"
@onready var fields: Control = $"hud/fields"
#endregion
#region Local Variables

var skin: UISkin
var stage: StageBG
var camera: Camera2D
var current_hud: Control
var health_bar: Control
var music: AudioStreamPlayer
var hud_beat_interval: int = 4
var mutable_streams: Array[AudioStreamPlayer] = []
var initial_ui_zoom: Vector2 = Vector2.ONE
var _need_to_play_music: bool = true
var modchart_pack: ModchartPack

#endregion
#region Node2D Functions

func _ready() -> void:
	Conductor.set_time(-(Conductor.crotchet * 5))
	if not is_instance_valid(Chart.global):
		Chart.global = Chart.request("test", SongItem.DEFAULT_DIFFICULTY_SET[1])
	# set up user interface skin
	skin = Chart.global.song_info.ui_skin
	combo_group.set_deferred("skin", Chart.global.song_info.ui_skin)
	combo_group.call_deferred("preload_combo")
	# make a modchart pack
	modchart_pack = ModchartPack.pack_from_folders([
		"res://assets/scripts",
		"res://assets/scripts/songs/%s" % Chart.global.song_info.folder,
	])
	modchart_pack.name = "modcharts"
	add_child(modchart_pack)

	modchart_pack.call_mod_method("_on_ready", [self])

	# kill the original hud
	$"hud/default".free()
	$"stage".free()
	# set up the note cluster
	note_cluster.note_queue = Chart.global.notes.duplicate()
	note_cluster._ready()
	# set up the actual HUD
	match Preferences.hud_style:
		1: load_hud(Globals.DEFAULT_HUD)
		2: load_hud(load("res://scenes/gameplay/hud/kade.tscn"))
		3: load_hud(load("res://scenes/gameplay/hud/psych.tscn"))
		4: load_hud(load("res://scenes/gameplay/hud/classic.tscn"))
		_: match Chart.global.song_info.name: # if you wanna load custom huds
			# -- Examples! --
			# "Lo-Fight", "Overhead", "Ballistic":
			#	load_hud(load("res://scenes/gameplay/hud/kade.tscn"))
			# "Psychic", "Wilter", "Uproar":
			#	load_hud(load("res://scenes/gameplay/hud/psych.tscn"))
			# "The Great Punishment" "Curious Cat", "Metamorphosis":
			#	load_hud(load("res://scenes/gameplay/hud/codename.tscn"))
			_:
				var hud_script: int = modchart_pack.call_mod_method("_set_hud", [self])
				if hud_script != ModchartPack.CallableRequest.STOP:
					load_hud(Globals.DEFAULT_HUD)

	init_stage("res://scenes/backgrounds/%s.tscn" % [Chart.global.song_info.background])
	init_music()
	init_fields()
	init_players(fields.get_children())

	initial_ui_zoom = ui_layer.scale

	# Connect Signals
	Conductor.istep_reached.connect(on_istep_reached)
	Conductor.ibeat_reached.connect(on_ibeat_reached)
	Conductor.ibar_reached.connect(on_ibar_reached)
	Conductor.ibeat_reached.connect(start_countdown)


func start_countdown(beat: int) -> void:
	var countdown_script: int = modchart_pack.call_mod_method("_on_countdown", [self, beat])
	if countdown_script != ModchartPack.CallableRequest.STOP:
		match beat:
			# display_countdown(sound_id, sprite_id)
			-4: display_countdown(0)
			-3: display_countdown(1)
			-2: display_countdown(2)
			-1: display_countdown(3)
	if beat == 0 and Conductor.ibeat_reached.is_connected(start_countdown):
		Conductor.ibeat_reached.disconnect(start_countdown)


func _process(delta: float) -> void:
	var process_script: int = modchart_pack.call_mod_method("_on_process", [self, delta])
	if process_script == ModchartPack.CallableRequest.STOP:
		return
	process_conductor(delta)
	if ui_layer.scale != initial_ui_zoom:
		ui_layer.scale = Vector2(
			lerpf(initial_ui_zoom.x, ui_layer.scale.x, exp(-delta * 5)),
			lerpf(initial_ui_zoom.y, ui_layer.scale.y, exp(-delta * 5))
		)
		center_ui_layer()
	if get_player(Preferences.playfield_side):
		update_healthbar(delta)
	modchart_pack.call_mod_method("_post_process", [self, delta])


func update_healthbar(delta: float) -> void:
	if not health_bar:
		return
	var health_deluxe: float = get_player(Preferences.playfield_side).health
	health_bar.value = lerpf(health_bar.value, health_deluxe, exp(-delta * 96))

func _unhandled_input(_e: InputEvent) -> void:
	modchart_pack.call_mod_method("_on_unhandled_input", [self, _e])
	if Input.is_action_just_pressed("ui_pause") and is_processing_unhandled_input():
		var pause_script: int = modchart_pack.call_mod_method("_on_pause", [self, _e])
		if pause_script != ModchartPack.CallableRequest.STOP:
			var pause_menu: Control = load("res://scenes/ui/pause/pause_menu.tscn").instantiate()
			pause_menu.z_index = 100
			get_tree().paused = true
			ui_layer.add_child(pause_menu)


func _exit_tree() -> void:
	var exit_script: int = modchart_pack.call_mod_method("_on_exit_tree", [self])
	if exit_script == ModchartPack.CallableRequest.STOP:
		return
	Conductor.istep_reached.disconnect(on_istep_reached)
	Conductor.ibeat_reached.disconnect(on_ibeat_reached)
	Conductor.ibar_reached.disconnect(on_ibar_reached)
	Conductor.reset()
	for i: int in fields.get_child_count():
		var field: NoteField = fields.get_child(i)
		if field.player:
			field.player.note_hit.disconnect(restore_vocals)
			field.player.note_hit.disconnect(update_score_text)
			field.player.note_hit.disconnect(combo_group.pop_up_judge)
			field.player.note_hit.disconnect(combo_group.pop_up_combo)
			field.player.note_fly_over.disconnect(miss_fly_over)

#endregions
#region Gameplay Setup

func init_fields() -> void:
	if not is_instance_valid(Chart.global):
		return

	var nf_config: = Chart.global.song_info.notefields
	for i: int in nf_config.size():
		var new_nf: NoteField
		var config: Dictionary = nf_config[i]
		if i < fields.get_child_count():
			new_nf = fields.get_child(i)
		else:
			new_nf = fields.get_child(0).duplicate()
			fields.add_child(new_nf)

		# characters #
		if "characters" in config and is_instance_valid(stage):
			for character: String in config.characters:
				if stage.has_node(character) and stage.get_node(character) is Character:
					new_nf.connected_characters.append(stage.get_node(character))
		if not "name" in config or config.name.is_empty():
			new_nf.name = &"%s" % str(new_nf.get_index()+1)
		Chart.global.song_info.configure_notefield(new_nf, config)

	for nf: NoteField in fields.get_children():
		nf.scale = Vector2(Preferences.receptor_size, Preferences.receptor_size)
		note_cluster.call_deferred("connect_notefield", nf)
		nf.reset_receptors()
		nf.reset_scrolls()


func init_players(player_fields: Array = []) -> void:
	for i: int in player_fields.size():
		if not player_fields[i] is NoteField:
			continue

		var field: NoteField = player_fields[i]
		var player: Player = Player.new()
		player.stats = PlayerStats.new()
		player.note_queue = note_cluster.note_queue.filter(func(note: Note):
			return note.player == field.get_index())

		for j: int in player.controls.size():
			# TODO ↓
			#player.controls[j] += "_p%s" % str(i + 1)
			player.held_buttons.append(false)

		player.note_hit.connect(restore_vocals)
		player.note_hit.connect(update_score_text)
		player.note_hit.connect(combo_group.pop_up_judge)
		player.note_hit.connect(combo_group.pop_up_combo)
		player.note_fly_over.connect(miss_fly_over)
		# send hit result so the score text updates
		player.botplay = i != Preferences.playfield_side
		field.make_playable(player)


func init_music() -> void:
	# SETUP MUSIC (temporary) #

	if not is_instance_valid(Chart.global):
		return

	var inst_stream: AudioStream = Chart.global.song_info.instrumental
	if inst_stream:
		music = AudioStreamPlayer.new()
		music.name = inst_stream.resource_path.get_file().get_basename()
		music.stream = inst_stream
		music.finished.connect(leave)
		music.stream.loop = false
		music.bus = "BGM"
		add_child(music)

	for vocal_stream: AudioStream in Chart.global.song_info.vocals:
		if not is_instance_valid(music): continue
		var vocals: = AudioStreamPlayer.new()
		vocals.name = vocal_stream.resource_path.get_file().get_basename()
		vocals.stream = vocal_stream
		vocals.stream.loop = false
		vocals.bus = music.bus
		#print_debug(vocals.name)
		music.add_child(vocals)

	if music:
		Conductor.length = music.stream.get_length()
	elif not note_cluster.note_queue.is_empty():
		Conductor.length = note_cluster.note_queue.back().time


func init_stage(path: NodePath) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Stage path ", path, " is inexistant or inaccessible, loading default stage...")
		stage = Globals.DEFAULT_STAGE.instantiate()
	else:
		stage = load(String(path)).instantiate()
		if stage.camera:
			camera = stage.camera

	add_child(stage)
	move_child(stage, 0)

	if not stage or Chart.global.song_info.characters.is_empty():
		push_warning("There are no characters in the chart metadata to load.")
		return

	for i: int in Chart.global.song_info.characters.size():
		var actor: String = Chart.global.song_info.characters[i]
		var char_path: = "res://scenes/characters/%s.tscn" % actor
		if not ResourceLoader.exists(char_path):
			push_warning("Tried to load character ", actor, " which doesn't exist in res://scenes/characters/")
			continue

		if stage.find_child("player%s" % str(i + 1)) == null:
			push_warning("Stage named ", stage.name, " has no Marker2D named player", str(i + 1), " skipping...")
			continue

		var marker: = stage.get_node("player%s" % str(i + 1))
		var character: Character = load(char_path).instantiate()
		character.global_position = marker.global_position
		character.name = "player%s" % str(i + 1)
		if i == 0: character._faces_left = true

		var index: int = marker.get_index()
		stage.remove_child(marker)
		stage.add_child(character)
		stage.move_child(character, index)

	if current_hud:
		current_hud.call_deferred("setup_healthbar")

#endregion
#region Gameplay Loop

func display_countdown(snd_progress: int, spr_progress: int = -0) -> void:
	if is_same(spr_progress, -0):
		spr_progress = snd_progress

	if spr_progress > -1 and spr_progress <= skin.countdown_sprites.size():
		var countdown_sprite: Sprite2D = Sprite2D.new()
		countdown_sprite.texture = skin.countdown_sprites[spr_progress]
		countdown_sprite.position = get_viewport_rect().size * 0.5
		countdown_sprite.scale.y += 0.2
		ui_layer.add_child(countdown_sprite)

		# animation :o #
		create_tween().set_ease(Tween.EASE_IN).bind_node(countdown_sprite).set_parallel(true) \
		.tween_property(countdown_sprite, "scale:y", countdown_sprite.scale.y - 0.2, 0.15 * Conductor.crotchet)

		create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).bind_node(countdown_sprite) \
		.tween_property(countdown_sprite, "modulate:a", 0.0, 1.25 * Conductor.crotchet).set_delay(0.2 * Conductor.crotchet) \
		.finished.connect(countdown_sprite.queue_free)

	if snd_progress > -1 and snd_progress <= skin.countdown_sounds.size():
		SoundBoard.play_sfx(skin.countdown_sounds[snd_progress])


func process_conductor(delta: float) -> void:
	var offset: float = (Preferences.beat_offset * 0.001)
	if _need_to_play_music:
		Conductor.update((Conductor.time) + delta)
		if Conductor.time >= 0.0:
			if music:
				music.play(0.0)
				for track: AudioStreamPlayer in music.get_children():
					track.play(0.0)
				_need_to_play_music = false
	elif music and music.playing:
		var time: float = music.get_playback_position() + AudioServer.get_time_since_last_mix()
		Conductor.update(time + offset)


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


func on_ibar_reached(ibar: int) -> void:
	var _bar_script: int = modchart_pack.call_mod_method("_on_ibar_reached", [self, ibar])
	#if bar_script == ModchartPack.CallableRequest.STOP:
	#	return

## Connected to [code]player.note_fly_over[/code] to handle
## missing notes by letting them fly above your notefield..
func miss_fly_over(note: Note) -> void:
	for field: NoteField in fields.get_children():
		if note.player == field.get_index() and field.player:
			var vocal: int = note.player % music.get_child_count()
			if music and music.get_child(vocal):
				music.get_child(vocal).volume_db = linear_to_db(0.0)
			#field.player.apply_miss(note.column)
			combo_group.pop_up_combo(note, true)
			update_score_text(note, true)
			note.finished = true


func restore_vocals(note: Note, _is_tap: bool) -> void:
	if not note:
		return
	for field: NoteField in fields.get_children():
		if note.player == field.get_index() and field.player and music:
			var vocal: = music.get_child(note.player % music.get_child_count())
			if vocal: vocal.volume_db = linear_to_db(1.0)


func leave() -> void:
	Conductor.reset() # reset rate
	Conductor.rate = 1.0
	# TODO: for levels, i need a playlist
	# and then we just switch to the next song
	# this is fine for now
	Globals.change_scene(load("res://scenes/menu/freeplay_menu.tscn"))

#endregion
#region HUD Elements

func center_ui_layer() -> void:
	ui_layer.offset = Vector2(
		(get_viewport_rect().size.x * -0.5) * (ui_layer.scale.x - 1.0),
		(get_viewport_rect().size.y * -0.5) * (ui_layer.scale.y - 1.0)
	)


func update_score_text(note: Note, is_tap: bool) -> void:
	if not current_hud or not note:
		return
	if current_hud.has_method("update_score_text"):
		current_hud.callv("update_score_text", [note.hit_result, is_tap])

#endregion
#region Utils

func load_hud(hud_scene: PackedScene, set_as_main: bool = true) -> void:
	var hud_name: StringName = hud_scene.resource_path.get_file().get_basename()
	if ui_layer.has_node(NodePath(hud_name)):
		push_warning("You're trying to load a hud that is already loaded!")
		return

	var instance: Control = hud_scene.instantiate()
	instance.name = hud_name
	ui_layer.add_child(instance)
	ui_layer.move_child(instance, 2)
	if set_as_main:
		current_hud = instance
		if instance.get("health_bar"):
			health_bar = instance.health_bar
			if instance.has_method("set_player"):
				instance.call_deferred("set_player", Preferences.playfield_side)

	modchart_pack.call_mod_method("_on_hud_loaded", [self, hud_name])


func unload_current_hud() -> void:
	if current_hud:
		unload_hud(current_hud.get_path())


func unload_hud(hud_name: NodePath) -> void:
	if ui_layer.has_node(hud_name):
		var old_hud: = ui_layer.get_node(hud_name)
		if old_hud.get("health_bar") and old_hud.health_bar == health_bar:
			health_bar = null
		old_hud.queue_free()
	modchart_pack.call_mod_method("_on_hud_unloaded", [self, hud_name])


func get_player(player_id: int) -> Player:
	for field: NoteField in fields.get_children():
		if field.player and player_id == field.get_index():
			return field.player
	return null

# temporary until godot 4.3
func resync_vocals() -> void:
	if not music:
		return
	for track: AudioStreamPlayer in music.get_children():
		track.seek(music.get_playback_position())
#endregion
