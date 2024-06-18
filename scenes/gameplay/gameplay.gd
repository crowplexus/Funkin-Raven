extends Node2D

@export var skin: UISkin

#region Scene Nodes

var camera: Camera2D
@onready var ui_layer: CanvasLayer = $"hud"
@onready var main_hud: Control = $"hud/main"
@onready var health_bar: = $"hud/main/health_bar"
@onready var status_label: Label = $"hud/main/status_label"
@onready var hit_result_label: Label = $"hud/main/judge"
@onready var note_cluster: Node2D = $"hud/main/note_cluster"
@onready var fields: Control = $"hud/main/fields"
@onready var stage: StageBG = $"stage"
#endregion
#region Local Variables

var music: AudioStreamPlayer
var hud_beat_interval: int = 4
var initial_ui_zoom: Vector2 = Vector2.ONE
var _need_to_play_music: bool = true

#endregion
#region Node2D Functions

func _ready() -> void:
	Conductor.active = false
	Conductor.set_time(-(Conductor.crotchet * 5))

	init_music()
	init_fields()

	init_players(fields.get_children())
	health_bar.set_player(Preferences.playfield_side)

	initial_ui_zoom = ui_layer.scale

	match Preferences.scroll_direction:
		1:
			health_bar.position.y = 100
			status_label.position.y = 135

	# Connect Signals
	Conductor.beat_reached.connect(on_beat_reached)
	Conductor.beat_reached.connect(start_countdown)
	Conductor.active = true


func start_countdown(beat: int) -> void:
	match beat:
		# process_countdown(sound_id, sprite_id)
		-4: process_countdown(0)
		-3: process_countdown(1)
		-2: process_countdown(2)
		-1: process_countdown(3)

	if beat == 0 and Conductor.beat_reached.is_connected(start_countdown):
		Conductor.beat_reached.disconnect(start_countdown)


func _process(delta: float) -> void:
	process_conductor(delta)
	if ui_layer.scale != initial_ui_zoom:
		ui_layer.scale = Vector2(
			lerpf(initial_ui_zoom.x, ui_layer.scale.x, exp(-delta * 5)),
			lerpf(initial_ui_zoom.y, ui_layer.scale.y, exp(-delta * 5))
		)
		center_ui_layer()
	if get_player(Preferences.playfield_side) != null:
		health_bar.value = lerpf(health_bar.value, get_player(Preferences.playfield_side).health, exp(-delta * 64))


func _unhandled_key_input(e: InputEvent) -> void:
	if e.is_pressed():
		match e.keycode:
			KEY_ESCAPE:
				get_tree().change_scene_to_packed(load("res://scenes/menu/freeplay_menu.tscn"))
			KEY_ENTER:
				if not get_tree().paused:
					var ow: Control = Globals.get_options_window()
					get_tree().paused = true
					ui_layer.add_child(ow)


func _exit_tree() -> void:
	Conductor.reset()
	Conductor.beat_reached.disconnect(on_beat_reached)
	for i: int in fields.get_child_count():
		var field: NoteField = fields.get_child(i)
		if is_instance_valid(field.player):
			field.player.note_hit.disconnect(update_score_text)
			field.player.note_hit.disconnect(show_combo_temporary)
			field.player.note_fly_over.disconnect(miss_fly_over)

#endregions
#region Gameplay Setup

func init_fields() -> void:
	for field: NoteField in fields.get_children():
		note_cluster.call_deferred("connect_notefield", field)
		field.reset_scroll_mods()


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
		player.note_hit.connect(show_combo_temporary)
		player.note_fly_over.connect(miss_fly_over)
		# send hit result so the score text updates
		var fake_result: = Note.HitResult.new()
		player.botplay = i != Preferences.playfield_side
		if Preferences.centered_playfield:
			# stupid check
			if (Preferences.playfield_side != -1 and player.botplay == false
				or Preferences.playfield_side == -1 and i == 0):
				field.playfield_warp = 0.5
			else:
				field.visible = false
		fake_result.player = player
		player.note_hit.emit(fake_result)
		field.make_playable(player)
		fake_result.unreference()


func init_music() -> void:
	# SETUP MUSIC (temporary) #

	if not is_instance_valid(Chart.global):
		return

	var track_path: String = "res://assets/songs/%s/" % Chart.global.song_info.folder
	var in_variation: bool = not Chart.global.song_info.difficulty.variation.is_empty()

	for fn: String in DirAccess.open(track_path).get_files():
		if in_variation:
			break

		if fn.get_extension() != "import":
			continue

		if not is_instance_valid(music):
			music = AudioStreamPlayer.new()
			music.stream = ResourceLoader.load(track_path + fn.get_basename())
			music.name = "%s" % fn.get_basename()
			music.stream.loop = false
			music.bus = "BGM"
			add_child(music)
			continue

		var vocals: = AudioStreamPlayer.new()
		vocals.stream = ResourceLoader.load(track_path + fn.get_basename())
		vocals.name = "%s" % fn.get_basename()
		vocals.stream.loop = false
		vocals.bus = music.bus
		music.add_child(vocals)

	#_need_to_play_music = is_instance_valid(music) and not music.playing
	if is_instance_valid(music):
		Conductor.length = music.stream.get_length()
	else:
		Conductor.length = note_cluster.note_queue.back().time
	##################

#endregion
#region Gameplay Loop

func process_countdown(snd_progress: int, spr_progress: int = -0) -> void:
	if is_same(spr_progress, -0):
		spr_progress = snd_progress

	if spr_progress > -1 and spr_progress <= skin.countdown_sprites.size():
		var countdown_sprite: Sprite2D = Sprite2D.new()
		countdown_sprite.texture = skin.countdown_sprites[spr_progress]
		countdown_sprite.position = get_viewport_rect().size * 0.5
		add_child(countdown_sprite)

		create_tween().set_ease(Tween.EASE_IN_OUT).bind_node(countdown_sprite) \
		.tween_property(countdown_sprite, "modulate:a", 0.0, 1.15 * Conductor.crotchet) \
		.finished.connect(countdown_sprite.queue_free)

	if snd_progress > -1 and snd_progress <= skin.countdown_sounds.size():
		SoundBoard.play_sfx(skin.countdown_sounds[snd_progress])


func process_conductor(delta: float) -> void:
	if not Conductor.active:
		return

	if _need_to_play_music:
		Conductor.time += delta
		if Conductor.time >= 0.0:
			if is_instance_valid(music):
				music.play(0.0)
				for track: AudioStreamPlayer in music.get_children():
					track.play(0.0)
				_need_to_play_music = false
	elif is_instance_valid(music) and music.playing:
		Conductor.time = music.get_playback_position() + AudioServer.get_time_since_last_mix()


func on_beat_reached(beat: int) -> void:
	if beat < 0:
		return

	if beat % hud_beat_interval == 0:
		ui_layer.scale += Vector2(0.03, 0.03)

## Connected to [code]player.note_fly_over[/code] to handle
## missing notes by letting them fly above your notefield..
func miss_fly_over(note: Note) -> void:
	for field: NoteField in fields.get_children():
		if note.player == field.get_index() and is_instance_valid(field.player):
			field.player.apply_miss(note.column)
			var fake_result: = Note.HitResult.new()
			fake_result.player = field.player
			update_score_text(fake_result)
			fake_result.unreference()

#endregion
#region HUD Elements

var combo_tween: Tween


func center_ui_layer() -> void:
	ui_layer.offset = Vector2(
		(get_viewport_rect().size.x * -0.5) * (ui_layer.scale.x - 1.0),
		(get_viewport_rect().size.y * -0.5) * (ui_layer.scale.y - 1.0)
	)


func update_score_text(hit_result: Note.HitResult) -> void:
	if not is_instance_valid(hit_result.player) or not is_instance_valid(status_label):
		return

	if main_hud.has_method("update_score_text"):
		main_hud.call_deferred("update_score_text", hit_result)
	else:
		status_label.text = hit_result.player.mk_stats_string()


func show_combo_temporary(hit_result: Note.HitResult) -> void:
	if hit_result.judgment == null or hit_result.judgment.is_empty():
		return

	var hit_colour: Color = Color.DIM_GRAY
	if "color" in hit_result.judgment:
		hit_colour = hit_result.judgment.color
	elif "colour" in hit_result.judgment: # british.
		hit_colour = hit_result.judgment.colour

	hit_result_label.text = (str(hit_result.judgment.name) +
		"\nTiming: %sms" % snappedf(hit_result.hit_time, 0.001) +
		"\nCombo: %s" % hit_result.player.combo)
	hit_result_label.modulate = hit_colour

	if is_instance_valid(combo_tween):
		combo_tween.kill()

	combo_tween = create_tween().set_ease(Tween.EASE_OUT)
	combo_tween.bind_node(hit_result_label)
	combo_tween.tween_property(hit_result_label, "modulate:a", 0.0, 0.5 * Conductor.crotchet) \
	.set_delay(0.5 * Conductor.crotchet)

#endregion
#region Utilities

func get_player(player_id: int) -> Player:
	for field: NoteField in fields.get_children():
		if is_instance_valid(field.player) and player_id == field.get_index():
			return field.player
	return null

#endregion
