class_name PlayField extends Control

static var chart: Chart
static var song_data: FreeplaySong
static var play_manager: Progression
static var death_count: int = 0

@onready var fields: Control = $notefields
@onready var health_bar: = $health_bar
@onready var score_text: Label = $score_text
@onready var time_text: Label = $time_text
@onready var combo_group: Control = $"combo_group"
@onready var judgement_counter: RichTextLabel = $judgement_counter
@onready var autoplay_text: Label = $autoplay_text
@onready var note_spawner: = $note_spawner
@onready var parent: Node:
	get:
		if get_tree().current_scene != null:
			return get_tree().current_scene
		elif $"../../" != null:
			return $"../../"
		else:
			return $"../"

@export var can_pause: bool = true
@export var enable_health: bool = true
@export var enable_zooming: bool = Settings.hud_bumping
@export var beats_to_bump: int = 4
@export var skin: UISkin

var default_scale: Vector2 = Vector2.ONE

var countdown_timer: Timer
var music: AudioStreamPlayer
var stats: Scoring:
	get: return play_manager.stats

var health: int = 50:
	set(v):
		health = clampi(v, 0, max_health)
var max_health: int = 100

var _skipping_time: bool = false
var _miss_health_inc: float = 0.0

#region Functions

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Conductor._reset()

	if play_manager == null:
		play_manager = Progression.new()

	if chart == null:
		chart = Chart.request("test", "hard")
		song_data = FreeplaySong.new()
		song_data.name = "Test"
		song_data.folder = "test"
		play_manager.difficulty = "hard"

	load_skin()

	if not enable_health:
		for sprite in health_bar.get_children(): sprite.free()
		health_bar.free()
	else:
		if Settings.enemy_play:
			health_bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END
		for i: Sprite2D in health_bar.get_children():
			i.set_script(Settings.icon_bump_script)
		reset_ui_position()

	if Settings.autoplay:
		autoplay_text.visible = Settings.autoplay
		autoplay_text.text = tr("game_autoplay_text")

	Conductor.on_beat.connect(on_beat)
	Conductor.on_step.connect(on_step)

	note_spawner.note_list = PlayField.chart.notes.duplicate()
	note_spawner.vinculated_fields.append_array(fields.get_children())
	note_spawner.enable_operate()

	if Settings.autoplay or Settings.practice: stats.valid_score = false
	if default_scale != self.scale: default_scale = self.scale

	self.pivot_offset = Vector2(
		(get_viewport_rect().size.x - self.size.x) * 0.5,
		(get_viewport_rect().size.y - self.size.y) * 0.5
	)

	stats.total_notes = chart.note_count[int(Settings.enemy_play)]

	for nf: NoteField in fields.get_children():
		var player_index: int = 1 if Settings.enemy_play else 0
		nf.is_cpu = nf.get_index() != player_index
		if nf.get_index() == player_index:
			nf.hit_behaviour = player_hit_behaviour
			nf.miss_behaviour = player_miss_behaviour
			nf.is_cpu = Settings.autoplay

		# little function chain so we can restore vocal volume
		var old_hb: Callable = nf.hit_behaviour
		nf.hit_behaviour = func(note: Note) -> void:
			# restore vocals volume each time any player hits a note
			if music != null:
				var main_vocal: AudioStreamPlayer = music.get_child(0)
				if main_vocal != null and main_vocal.volume_db < linear_to_db(1.0):
					main_vocal.volume_db = linear_to_db(1.0)
			old_hb.call(note)

		nf.set_speed(chart.initial_speed)

	await RenderingServer.frame_post_draw

	Conductor.time = -(Conductor.crotchet * 5)#+ Settings.note_offset
	Conductor.active = true
	combo_group.prepare()

	for stream: AudioStream in chart.metadata.get_tracks():
		# Master Track
		stream.loop = false
		if music == null and stream.resource_name.to_lower().find("inst") != -1:
			music = AudioStreamPlayer.new()
			music.stream = stream.duplicate()
			music.finished.connect(leave)
		# Children Tracks
		elif music != null:
			var vocal: AudioStreamPlayer = AudioStreamPlayer.new()
			vocal.stream = stream.duplicate()
			music.add_child(vocal)

	if music != null:
		add_child(music)
		Conductor.length = music.stream.get_length()

	update_score_counter.call()
	update_judgement_counter.call()
	update_timer_label.call()

func countdown(max_counts: int = 4) -> void:
	countdown_timer = Timer.new()
	add_child(countdown_timer)

	if parent != null:
		parent.call_deferred("modchart_call", "on_countdown_start")

	for i: int in max_counts+1:
		countdown_timer.start(Conductor.crotchet)
		await countdown_timer.timeout

		if i == max_counts:
			countdown_timer.queue_free()
			start_music()
			return

		if parent != null:
			parent.call_deferred("modchart_call", "on_countdown", [i])

		if skin.countdown_sfx[i] != null:
			SoundBoard.play_sfx(skin.countdown_sfx[i])

		if skin.countdown_sprites[i] != null:
			var countdown_spr: Sprite2D = skin.create_countdown_spr(i)
			countdown_spr.position = Vector2(640, 360)
			countdown_spr.name = "count" + str(i)
			add_child(countdown_spr)

			var twn: = create_tween()
			twn.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
			twn.set_parallel(true)
			twn.bind_node(countdown_spr)

			twn.tween_property(countdown_spr, "position:y", countdown_spr.position.y + 100, Conductor.crotchet)
			twn.tween_property(countdown_spr, "modulate:a", 0.0, Conductor.crotchet) \
			.finished.connect(countdown_spr.queue_free)

func _process(delta: float) -> void:
	if Conductor.active:
		process_gameplay(delta)
		if enable_zooming:
			handle_zooming()

	if health_bar != null:
		handle_health_bar(delta)

func handle_zooming() -> void:
	if self.scale != Vector2.ONE:
		self.scale = Vector2(
			Tools.exp_lerp(scale.x, default_scale.x, 5),
			Tools.exp_lerp(scale.y, default_scale.y, 5)
		)

func handle_health_bar(delta: float) -> void:
	health_bar.value = Tools.exp_lerp(health_bar.value, health, 16, delta)

	for icon: Sprite2D in health_bar.get_children():
		var lr_axis: int = -1 if health_bar.fill_mode == ProgressBar.FILL_BEGIN_TO_END else 1
		var icon_health: int = health if icon.flip_h else 100 - health
		if lr_axis == -1: # inver calc, MAKE THIS NOT WEIRD LATER LOL
			icon_health = 100 - health if icon.flip_h else health

		var hb_offset: int = 0 if lr_axis == -1 else health_bar.size.x
		icon.frame = 1 if icon_health < 20 else 0
		icon.position.x = -(health_bar.value * health_bar.size.x / 100) + hb_offset
		icon.position.x *= lr_axis

func start_music() -> void:
	if music == null:
		printerr("Music Node in PlayField is null, so no music will be played.")
		return
	music.play(0.0)
	for track: AudioStreamPlayer in music.get_children():
		track.play(music.get_playback_position())

func stop_music() -> void:
	if music == null:
		printerr("Music Node in PlayField is null, so there's nothing to be stopped.")
		return
	music.stop()
	for track: AudioStreamPlayer in music.get_children():
		track.stop()

func process_gameplay(delta: float) -> void:
	if music == null:
		Conductor.time += delta
		if note_spawner.note_list.size() == 0:
			if parent != null and parent.ending_cutscene != null:
				parent.ending_cutscene.call_deferred()
			else:
				leave()
	else:
		if Conductor.time > Conductor.length: return
		if not music.playing:
			Conductor.time += delta
		else:
			Conductor.time = music.get_playback_position() + AudioServer.get_time_since_last_mix()

	if Conductor.time >= 0.0 and OS.is_debug_build():
		if Input.is_key_label_pressed(KEY_4):
			stats.valid_score = false
			Conductor.active = false
			stop_music()
			leave()

		if Input.is_key_label_pressed(KEY_5):
			if music != null:
				music.seek(music.get_playback_position() + 0.5)
			else:
				Conductor.time *= 0.5
			_skipping_time = true
			for nf: NoteField in fields.get_children():
				nf.clear_notes()
			_skipping_time = false
			if music != null:
				resync_tracks(true)

func on_beat(beat: int) -> void:
	if enable_zooming and beat % beats_to_bump == 0:
		self.scale += Vector2(0.015, 0.015)
	if health_bar != null:
		for icon: Sprite2D in health_bar.get_children():
			if icon.has_method("bump"):
				icon.call_deferred("bump")
	resync_tracks()

func on_step(step: int) -> void:
	if step % 1 == 0:
		update_timer_label.call()

var _score_mult_result: int = 0

var update_score_counter: Callable = func() -> void:
	if score_text == null or score_text.visible == false:
		return

	var score_mult_str: String = ""
	if Settings.enable_combo_multiplier and _score_mult_result > 1:
		score_mult_str = " [x%s]" % _score_mult_result

	var eval_str: String = ""
	if not stats.current_grade.is_empty():
		eval_str = " [%s]" % stats.current_grade

	var base: StringName = "{score}: %s • {breaks}: %s • {accuracy}: %s" % [
		str(stats.score) + score_mult_str,
		stats.breaks,
		stats.accuracy_to_str() + eval_str
	]

	score_text.text = "< %s >" % ( base
		.replace("{score}", tr("info_score"))
		.replace("{breaks}", tr("info_breaks"))
		.replace("{accuracy}", tr("info_accuracy")) )

var update_timer_label: Callable = func() -> void:
	if time_text == null or time_text.visible == false:
		return

	time_text.text = "~ %s ~\n" % PlayField.song_data.name
	time_text.text += "%s / %s" % [
		"00:00" if Conductor.time < 0 else Tools.format_to_time(Conductor.time),
		Tools.format_to_time(Conductor.length)
	]

var update_judgement_counter: Callable = func() -> void:
	if judgement_counter == null or judgement_counter.visible == false:
		return

	judgement_counter.text = ""
	for i: int in Highscore.judgements.size():
		var judgement: Dictionary = Highscore.judgements[i]
		if judgement.timing == -1:
			continue

		judgement_counter.text += "[color=%s]%s[/color]: %s\n" % [
			judgement.color.to_html(), tr("judgement_" + judgement.name), stats.judgements_hit[i]
		]

	if Settings.miss_limiter != 1:
		judgement_counter.text += "%s: %s" % [tr("info_misses"), stats.misses + stats.ghost_taps]
		if Settings.miss_limiter > 1:
			judgement_counter.text += " / %s" % Settings.miss_limiter

	judgement_counter.text += "\n\n%s: %s" % [tr("info_clear_flag"), stats.get_clear_flag()]
	if Settings.judgement_counter == 2:
		judgement_counter.text = "[right]%s[/right]" % judgement_counter.text

func player_hit_behaviour(note: Note) -> void:
	if note == null or note.was_hit: return
	note.was_hit = true
	note.on_hit()

	var judge_cancel: bool = (note.data.has("cancel_judge_check")
														and note.data["cancel_judge_check"] == true)

	if note.arrow.visible and not judge_cancel:
		var note_time: float = absf(note.get_time_offseted() - Conductor.time)
		var judgement_id: int = Scoring.judge_time(note_time)
		var judgement: Dictionary = Highscore.judgements[judgement_id]
		note.judgement = judgement

		#var is_late: bool = note.data.time < Conductor.time
		var can_splash: bool = Settings.note_splashes and note.splash != null
		if can_splash and (judgement.splash == true or note.force_splash):
			note.splash.modulate.a = Settings.note_splash_a * 0.01
			note.pop_splash()

		stats.score += floori(100 * absf(judgement.timing / note_time))
		stats.stored_time += note_time

		if not Settings.practice:
			if Settings.enable_combo_multiplier:
				_score_mult_result = floori(1 + (stats.combo / Settings.combo_mult_weight))
				stats.score += _score_mult_result

			_miss_health_inc = 0.0
			if stats.combo < 0: stats.combo = 0 # safety check
			var cb_judges: PackedStringArray = ["bad", "shit"]
			if not Settings.use_epics: cb_judges.remove_at(0)
			for combo_break_judge in cb_judges:
				if judgement.name.to_snake_case() == combo_break_judge and stats.combo >= 1:
					stats.breaks += 1
					stats.combo = 0
			stats.combo += 1
			health += 2

		var judge_pop_cancel: bool = (note.data.has("cancel_judgement_popup")
														and note.data["cancel_judgement_popup"] == true)
		var combo_pop_cancel: bool = (note.data.has("cancel_combo_popup")
														and note.data["cancel_combo_popup"] == true)

		stats.update_hits(judgement_id, 1)
		stats.update_accuracy(judgement_id, note_time)
		if combo_group != null:
			if not judge_pop_cancel:
				await RenderingServer.frame_post_draw
				combo_group.display_judgement(judgement_id)
			if not combo_pop_cancel and not Settings.practice:
				combo_group.display_combo(stats.combo)
		update_score_counter.call()
		update_judgement_counter.call()

	if note != null and not note.is_sustain and not note.prevent_disposal:
		note.queue_free()

func player_miss_behaviour(note: Note, _dir: int) -> void:
	if note == null:
		stats.ghost_taps += 1
	else:
		note.missed = true
		note.on_miss()

	if not Settings.practice:
		_score_mult_result = 0
		if note != null: stats.misses += 1
		if stats.combo >= 1: stats.breaks += 1
		if note != null: stats.combo = 0
		stats.score -= 25
		health -= 2 + floori(_miss_health_inc)
		_miss_health_inc += 0.15

		if Settings.miss_limiter != 0 and (stats.misses + stats.ghost_taps) >= Settings.miss_limiter:
			if parent != null and parent.has_method("kill_player"):
				parent.kill_player()

	SoundBoard.play_sfx(skin.miss_sounds.pick_random(), 1.0, randf_range(0.1, 0.2))

	# mute vocals
	if music != null:
		var main_vocal: AudioStreamPlayer = music.get_child(0)
		if main_vocal != null and main_vocal.volume_db > linear_to_db(0.0):
			main_vocal.volume_db = linear_to_db(0.0)

	update_score_counter.call()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Conductor.on_beat.disconnect(on_beat)
	Conductor.on_step.disconnect(on_step)
	Conductor._reset()

func resync_tracks(force: bool = false) -> void:
	if music == null: return
	for track: AudioStreamPlayer in music.get_children():
		if force or SoundBoard.is_track_desynced(track, music):
			track.seek(music.get_playback_position())

func _unhandled_key_input(e: InputEvent) -> void:
	if not is_node_ready() or not e.pressed:
		return

	match e.keycode:
		KEY_ENTER:
			if can_pause and not get_tree().paused:
				get_tree().paused = true
				var pause_menu: Control = load("res://raven/menu/pause_menu.tscn").instantiate()
				pause_menu.z_index = 5
				pause_menu.exit_callback = func() -> void:
					autoplay_text.visible = Settings.autoplay
					if Settings.autoplay or Settings.practice:
						stats.valid_score = false

					for nf: NoteField in fields.get_children():
						nf.set_scroll(Settings.scroll)
						var player_index: int = 1 if Settings.enemy_play else 0
						if nf.get_index() == player_index:
							nf.is_cpu = Settings.autoplay

					reset_ui_position()
					reset_combo_group_position()
					judgement_counter.visible = Settings.judgement_counter != 0
				add_child(pause_menu)
		KEY_F7: leave(2)

func leave(exit_code: int = -1) -> void:
	if exit_code == -1: exit_code = play_manager.play_mode
	if parent != null:
		parent.call_deferred("modchart_call", "on_game_end", [exit_code])

	if exit_code != 2 and Settings.show_eval_screen:
		var eval_screen: Control = load("res://raven/ui/play/evaluation_screen.tscn").instantiate()
		eval_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		eval_screen.close_callback = func() -> void:
			play_manager.end_play_session(exit_code)
		self.process_mode = Node.PROCESS_MODE_DISABLED
		eval_screen.z_index = 10
		add_child(eval_screen)
	else:
		play_manager.end_play_session(exit_code)

func load_skin() -> void:
	await RenderingServer.frame_post_draw
	if chart != null and chart.metadata.skin != null:
		skin = chart.metadata.skin
	else:
		skin = load("res://assets/ui/normal/config.tres")

	combo_group.skin = skin
	reset_combo_group_position()

func reset_ui_position() -> void:
	match Settings.scroll:
		1:
			health_bar.position.y = 60
			#score_text.position.y = health_bar.position.y + 40
			#time_text.position.y = get_viewport_rect().size.y - 60
		_:
			health_bar.position.y = get_viewport_rect().size.y - 90
			#score_text.position.y = health_bar.position.y + 40
			#time_text.position.y = 10

	if parent != null and parent.has_method("reset_health_bar_colors"):
		parent.reset_health_bar_colors()

func reset_combo_group_position() -> void:
	if combo_group == null:
		print_debug("no combo group found.")
		return

	var viewport: = get_viewport_rect().size
	match Settings.judgement_placement:
		0: # World
			if combo_group.get_parent() != get_tree().current_scene:
				combo_group.reparent(get_tree().current_scene)
				combo_group.z_index = 1
				#combo_group = parent.get_node("combo_group")
			combo_group.position = Vector2(viewport.x * 0.03, viewport.y * 0.05)
			combo_group.scale = Vector2.ONE
		1: # HUD
			combo_group.position.x = 640
			match Settings.scroll:
				1,3: combo_group.position.y = (viewport.y - 520)
				0,2: combo_group.position.y = (viewport.y - 180)
			if combo_group.get_parent() != self:
				combo_group.reparent(self)
				#combo_group = get_node("combo_group")
			combo_group.scale = Vector2(0.7, 0.7)
#endregion
