extends Node2D

@export var skin: UISkin

#region Scene Nodes

var camera: Camera2D
@onready var ui_layer: CanvasLayer = $"hud"
@onready var combo_group: Control = $"hud/combo_group"
@onready var note_cluster: Node2D = $"hud/note_cluster"
@onready var event_mach: EventMachine = $"event_machine"
@onready var fields: Control = $"hud/fields"
#endregion
#region Local Variables

var stage: StageBG
var current_hud: Control
var health_bar: Control
var music: AudioStreamPlayer
var hud_beat_interval: int = 4
var initial_ui_zoom: Vector2 = Vector2.ONE
var _need_to_play_music: bool = true

#endregion
#region Node2D Functions

func _ready() -> void:
	Conductor.set_time(-(Conductor.crotchet * 5))

	if not is_instance_valid(Chart.global):
		Chart.global = Chart.request("test", SongItem.DEFAULT_DIFFICULTY_SET[1])

	note_cluster.note_queue = Chart.global.notes.duplicate()
	note_cluster._ready()
	$"hud/default".free()
	$"stage".free()

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
				load_hud(Globals.DEFAULT_HUD)

	var np: NodePath = "res://scenes/backgrounds/%s.tscn" % [
		Chart.global.song_info.background]
	#print_debug("trying to create stage")
	init_stage(np)

	init_music()
	init_fields()
	init_players(fields.get_children())

	initial_ui_zoom = ui_layer.scale

	# Connect Signals
	Conductor.ibeat_reached.connect(on_ibeat_reached)
	Conductor.ibeat_reached.connect(start_countdown)


func start_countdown(beat: int) -> void:
	match beat:
		# display_countdown(sound_id, sprite_id)
		-4: display_countdown(0)
		-3: display_countdown(1)
		-2: display_countdown(2)
		-1: display_countdown(3)

	if beat == 0 and Conductor.ibeat_reached.is_connected(start_countdown):
		Conductor.ibeat_reached.disconnect(start_countdown)


func _process(delta: float) -> void:
	process_conductor(delta)
	if ui_layer.scale != initial_ui_zoom:
		ui_layer.scale = Vector2(
			lerpf(initial_ui_zoom.x, ui_layer.scale.x, exp(-delta * 5)),
			lerpf(initial_ui_zoom.y, ui_layer.scale.y, exp(-delta * 5))
		)
		center_ui_layer()

	if is_instance_valid(health_bar) and is_instance_valid(get_player(Preferences.playfield_side)):
		var health_deluxe: float = get_player(Preferences.playfield_side).health
		health_bar.value = lerpf(health_bar.value, health_deluxe, exp(-delta * 96))


func _unhandled_key_input(e: InputEvent) -> void:
	if e.is_pressed():
		match e.keycode:
			KEY_ESCAPE:
				get_tree().change_scene_to_packed(load("res://scenes/menu/freeplay_menu.tscn"))
			KEY_ENTER:
				if not get_tree().paused:
					var ow: Control = Globals.get_options_window()
					get_tree().paused = true
					PerformanceCounter.add_child(ow)


func _exit_tree() -> void:
	Conductor.reset()
	Conductor.ibeat_reached.disconnect(on_ibeat_reached)
	for i: int in fields.get_child_count():
		var field: NoteField = fields.get_child(i)
		if is_instance_valid(field.player):
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
		note_cluster.call_deferred("connect_notefield", nf)
		nf.reset_scroll_mods()


func init_players(player_fields: Array = []) -> void:
	for i: int in player_fields.size():
		if not player_fields[i] is NoteField:
			continue

		var field: NoteField = player_fields[i]
		var player: Player = Player.new()
		player.note_queue = note_cluster.note_queue.filter(func(note: Note):
			return note.player == field.get_index())

		for j: int in player.controls.size():
			# TODO ↓
			#player.controls[j] += "_p%s" % str(i + 1)
			player.held_buttons.append(false)

		player.note_hit.connect(update_score_text)
		player.note_hit.connect(combo_group.pop_up_judge)
		player.note_hit.connect(combo_group.pop_up_combo)
		player.note_fly_over.connect(miss_fly_over)
		# send hit result so the score text updates
		player.botplay = i != Preferences.playfield_side
		if Preferences.centered_playfield:
			# stupid check
			if (Preferences.playfield_side != -1 and player.botplay == false
				or Preferences.playfield_side == -1 and i == 0):
				field.playfield_spot = 0.5
			else:
				field.visible = false
		field.make_playable(player)


func init_music() -> void:
	# SETUP MUSIC (temporary) #

	if not is_instance_valid(Chart.global):
		return

	var inst_stream: AudioStream = Chart.global.song_info.instrumental
	if is_instance_valid(inst_stream):
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

	if is_instance_valid(music):
		Conductor.length = music.stream.get_length()
	else:
		Conductor.length = note_cluster.note_queue.back().time


func init_stage(path: NodePath) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Stage path ", path, " is inexistant or inaccessible, loading default stage...")
		stage = Globals.DEFAULT_STAGE.instantiate()
	else:
		stage = load(String(path)).instantiate()
		if is_instance_valid(stage.camera):
			camera = stage.camera

	add_child(stage)
	move_child(stage, 0)

	if not is_instance_valid(stage) or Chart.global.song_info.characters.is_empty():
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

		var index: int = marker.get_index()
		stage.remove_child(marker)
		stage.add_child(character)
		stage.move_child(character, index)

	if is_instance_valid(current_hud):
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
	if _need_to_play_music:
		Conductor.update(Conductor.time + delta)
		if Conductor.time >= 0.0:
			if is_instance_valid(music):
				music.play(0.0)
				for track: AudioStreamPlayer in music.get_children():
					track.play(0.0)
				_need_to_play_music = false
	elif is_instance_valid(music) and music.playing:
		Conductor.update(music.get_playback_position() + AudioServer.get_time_since_last_mix())


func on_ibeat_reached(ibeat: int) -> void:
	if ibeat < 0:
		return

	if ibeat % hud_beat_interval == 0:
		ui_layer.scale += Vector2(0.03, 0.03)

	if is_instance_valid(music) and music.get_child_count() != 0:
		for track: AudioStreamPlayer in music.get_children():
			if (music.get_playback_position() - track.get_playback_position()) > 0.01:
				resync_vocals()

## Connected to [code]player.note_fly_over[/code] to handle
## missing notes by letting them fly above your notefield..
func miss_fly_over(note: Note) -> void:
	for field: NoteField in fields.get_children():
		if note.player == field.get_index() and is_instance_valid(field.player):
			#field.player.apply_miss(note.column)
			var fake_result: = Note.HitResult.new()
			fake_result.player = field.player
			combo_group.pop_up_combo(fake_result, true)
			update_score_text(fake_result, true)
			fake_result.unreference()


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


func update_score_text(hit_result: Note.HitResult, is_tap: bool) -> void:
	if not is_instance_valid(hit_result.player) or not is_instance_valid(current_hud):
		return

	if current_hud.has_method("update_score_text"):
		current_hud.callv("update_score_text", [hit_result, is_tap])

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
		if instance.get("health_bar") != null:
			health_bar = instance.health_bar
			health_bar.set_player(Preferences.playfield_side)


func unload_current_hud() -> void:
	if is_instance_valid(current_hud):
		current_hud.queue_free()


func unload_hud(hud_name: NodePath) -> void:
	if ui_layer.has_node(hud_name):
		ui_layer.get_node(hud_name).queue_free()


func get_player(player_id: int) -> Player:
	for field: NoteField in fields.get_children():
		if is_instance_valid(field.player) and player_id == field.get_index():
			return field.player
	return null

# temporary until godot 4.3
func resync_vocals() -> void:
	if not is_instance_valid(music):
		return
	for track: AudioStreamPlayer in music.get_children():
		track.seek(music.get_playback_position())
#endregion
