class_name PlayField extends Control

static var chart: Chart
static var song_data: FreeplaySong
static var play_manager: PlayManager
static var death_count: int = 0

var NOTE_TYPES: Array[PackedScene] = [
	preload("res://raven/game/notes/default.tscn")
]

@onready var strums: Control = $notefields
@onready var combo_group: Control = $combo_group
@onready var health_bar: = $health_bar
@onready var score_text: Label = $score_text
@onready var autoplay_text: Label = $autoplay_text
@onready var parent:
	get:
		if $"../../" == null or $"../" == null:
			return null
		if $"../../".name.to_lower() == "gameplay":
			return $"../../"
		return $"../"

@export var can_pause: bool = true
@export var enable_health: bool = true
@export var enable_zooming: bool = Settings.hud_bumping
@export var beats_to_bump: int = 4

var skin: UISkin
var default_play_scale: Vector2 = Vector2.ONE

var note_list: Array[NoteData] = []
var event_list: Array[EventData] = []
var current_note: int = 0

var countdown_timer: Timer
var music: AudioStreamPlayer
var points: ScoreManager:
	get: return play_manager.points

var health: int = 50:
	set(v):
		health = clampi(v, 0, max_health)
var max_health: int = 100

var _skipping_time: bool = false
var _miss_health_inc: float = 0.0

#region Functions

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Conductor._reset()
	
	if play_manager == null:
		play_manager = PlayManager.new()
	
	if chart == null:
		chart = Chart.request("dadbattle", "hard")
		song_data = FreeplaySong.new()
		song_data.name = "Dadbattle"
		song_data.folder = "dadbattle"
		play_manager.difficulty = "hard"
	
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
	
	Conductor.on_step.connect(on_step)
	Conductor.on_beat.connect(on_beat)
	Conductor.on_beat.connect(on_bar )
	
	if Settings.autoplay or Settings.practice:
		points.valid_score = false
	
	if default_play_scale != self.scale: default_play_scale = self.scale
	self.pivot_offset = Vector2(
		(get_viewport_rect().size.x - self.size.x) * 0.5,
		(get_viewport_rect().size.y - self.size.y) * 0.5
	)
	
	note_list = chart.notes.duplicate()
	event_list = chart.events.duplicate()
	
	for nf: NoteField in strums.get_children():
		var player_index: int = 1 if Settings.enemy_play else 0
		nf.is_cpu = nf.get_index() != player_index
		if nf.get_index() == player_index:
			nf.hit_behavior = player_hit_behavior
			nf.miss_behavior = player_miss_behavior
			nf.is_cpu = Settings.autoplay
			
		# little function chain so we can restore vocal volume
		var old_hb: Callable = nf.hit_behavior
		nf.hit_behavior = func(note: Note):
			# restore vocals volume each time any player hits a note
			if music != null:
				for track: AudioStreamPlayer in music.get_children():
					if track.volume_db > linear_to_db(1.0): continue
					track.volume_db = linear_to_db(1.0)
			old_hb.call(note)
		
		nf.set_speed(chart.initial_speed)
	load_skin()
	
	Conductor.time = -(Conductor.beatc * 5)
	Conductor.active = true
	
	var music_path: String = Chart.get_chart_path(song_data.folder)+"/audio"
	
	for stream: AudioStream in SoundBoard.get_streams_at(music_path):
		# Master Track
		stream.loop = false
		if music == null and stream.resource_name.to_lower().find("inst") != -1:
			music = AudioStreamPlayer.new()
			music.stream = stream
			music.finished.connect(leave)
		# Children Tracks
		elif music != null:
			var vocal: AudioStreamPlayer = AudioStreamPlayer.new()
			vocal.stream = stream
			music.add_child(vocal)
	add_child(music)
	
	if music != null: Conductor.length = music.stream.get_length()
	update_score_counter.call()

func countdown(max_counts: int = 4):
	countdown_timer = Timer.new()
	add_child(countdown_timer)
	if parent != null:
		parent.call_deferred("modchart_call", "on_countdown_start")
	
	for i: int in max_counts:
		countdown_timer.start(Conductor.beatc)
		if i == max_counts: countdown_timer.queue_free()
		
		await countdown_timer.timeout
		
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
			
			twn.tween_property(countdown_spr, "position:y", countdown_spr.position.y + 100, Conductor.beatc)
			twn.tween_property(countdown_spr, "modulate:a", 0.0, Conductor.beatc) \
			.finished.connect(countdown_spr.queue_free)

func _process(delta: float):
	if Conductor.active:
		process_gameplay(delta)
		call_deferred_thread_group("invoke_notes")
	
	if enable_zooming and self.scale != Vector2.ONE:
		self.scale = Vector2(
			Tools.lerp_fix(scale.x, default_play_scale.x, delta, 5),
			Tools.lerp_fix(scale.y, default_play_scale.y, delta, 5)
		)
	if health_bar != null:
		health_bar.value = health
		for icon: Sprite2D in health_bar.get_children():
			var lr_axis: int = -1 if health_bar.fill_mode == ProgressBar.FILL_BEGIN_TO_END else 1
			var icon_health: int = health if icon.flip_h else 100 - health
			if lr_axis == -1: # inver calc, MAKE THIS NOT WEIRD LATER LOL
				icon_health = 100 - health if icon.flip_h else health
			
			var hb_offset: int = 0 if lr_axis == -1 else health_bar.size.x
			icon.frame = 1 if icon_health < 20 else 0
			icon.position.x = -(health_bar.value * health_bar.size.x / 100) + hb_offset
			icon.position.x *= lr_axis

func start_music():
	if music == null: return
	music.play(0.0)
	for track: AudioStreamPlayer in music.get_children():
		track.play(music.get_playback_position())

func stop_music():
	if music == null: return
	music.stop()
	for track: AudioStreamPlayer in music.get_children():
		track.stop()

func process_gameplay(delta: float):
	if music == null:
		Conductor.time += delta
		if note_list.size() == 0:
			if parent != null and parent.ending_cutscene != null:
				parent.ending_cutscene.call_deferred()
			else:
				leave()
	else:
		if Conductor.time > Conductor.length: return
		if not music.playing:
			Conductor.time += delta
			if Conductor.time >= 0.0:
				if parent != null:
					parent.call_deferred("modchart_call", "on_song_start")
				start_music()
		else:
			Conductor.time = music.get_playback_position() + AudioServer.get_time_since_last_mix()
	
	if Conductor.time >= 0.0:
		if Input.is_key_label_pressed(KEY_4):
			points.valid_score = false
			Conductor.active = false
			stop_music()
			leave()
		
		if Input.is_key_label_pressed(KEY_5):
			music.seek(music.get_playback_position() + 0.5)
			_skipping_time = true
			for nf: NoteField in strums.get_children():
				nf.clear_notes()
			_skipping_time = false
			resync_tracks(true)

func on_beat(beat: int):
	if enable_zooming and beat % beats_to_bump == 0:
		self.scale += Vector2(0.015, 0.015)
	if health_bar != null:
		for icon: Sprite2D in health_bar.get_children():
			if icon.has_method("bump"):
				icon.call_deferred("bump")
	resync_tracks()

func on_step(_step: int): pass
func on_bar (_bar: int): pass

func invoke_notes():
	if note_list.size() == 0: return
	while not _skipping_time and current_note < note_list.size():
		var laneid: int = note_list[current_note].lane+1
		var notefield: NoteField = strums.get_node("player%s"%laneid) as NoteField
		var dir: int = note_list[current_note].dir % notefield.receptors.get_child_count()
		var receptor: Receptor = notefield.receptors.get_child(dir) as Receptor
		
		if notefield == null or receptor == null:
			current_note += 1
			break
		
		if (note_list[current_note].time-Conductor.time) > (1.5 / receptor.speed):
			break
		
		var new_note: = NOTE_TYPES[0].instantiate()
		new_note.data = note_list[current_note].duplicate()
		notefield.note_group.add_child(new_note)
		current_note += 1

var update_score_counter: Callable = func():
	if score_text == null: return
	var eval_str: String = ""
	if not points.current_evaluation.is_empty():
		eval_str = " [%s]" % points.current_evaluation
	
	var base: StringName = "{score}:%s • {accuracy}:%s" % [
		points.score, points.accuracy_to_str() + eval_str
	]
	
	var limiter_str: String = ""
	if Settings.miss_limiter > 1:
		limiter_str = " / %s " % Settings.miss_limiter
	
	if Settings.miss_limiter != 1:
		base = "{misses}:%s" % [str(points.misses + points.ghost_taps) + limiter_str + " • " + base]
	
	base = "< " + base + " >"
	
	score_text.text = base \
		.replace("{misses}", tr("info_misses")) \
		.replace("{score}", tr("info_score")) \
		.replace("{accuracy}", tr("info_accuracy"))

func player_hit_behavior(note: Note):
	if note == null or note.was_hit: return
	note.was_hit = true
	note.on_hit()
	
	if note.arrow.visible:
		var note_ms: float = absf(note.data.time - Conductor.time)
		var judgement: String = Highscore.judgement_from_time(note_ms)
		var judgement_data: Array = Highscore.judgements[judgement]
		#var is_late: bool = note.data.time < Conductor.time
		
		if Settings.splashes and (judgement_data[3] == true or note.force_splash):
			note.splash()
		
		points.score += judgement_data[0]
		points.update_hits(judgement, 1)
		
		if not Settings.practice:
			_miss_health_inc = 0.0
			if points.combo < 0: points.combo = 0 # safety check
			points.combo += 1
			health += 2
		
		points.update_accuracy(maxi(judgement_data[2], 0))
		combo_group.display_judgement(judgement)
		if not Settings.practice:
			combo_group.display_combo(points.combo)
		update_score_counter.call()
	
	if note.is_sustain:
		var sustain_score: int = note.sustain_score
		#print_debug("ハロー！！！！！　：　", sustain_score)
		points.score += sustain_score
		update_score_counter.call()
	
	if not note.is_sustain and not note.prevent_disposal:
		note.queue_free()

func player_miss_behavior(note: Note, _dir: int):
	if note == null: points.ghost_taps += 1
	else:
		note.missed = true
		note.on_miss()
	
	if not Settings.practice:
		if note != null: points.misses += 1
		points.combo = 0
		points.score -= 10
		health -= 2 + floori(_miss_health_inc)
		if not Settings.practice:
			_miss_health_inc += 0.15
		
		if Settings.miss_limiter != 0 and (points.misses + points.ghost_taps) >= Settings.miss_limiter:
			if parent != null and parent.has_method("kill_player"):
				parent.kill_player()
	
	SoundBoard.play_sfx(skin.miss_sounds.pick_random(), 1.0, randf_range(0.1, 0.2))
	
	# mute vocals
	if music != null:
		for track: AudioStreamPlayer in music.get_children():
			if track.volume_db == linear_to_db(0.0): break
			track.volume_db = linear_to_db(0.0)
	
	update_score_counter.call()

func _exit_tree():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Conductor.on_step.disconnect(on_step)
	Conductor.on_beat.disconnect(on_beat)
	Conductor.on_beat.disconnect(on_bar )
	Conductor._reset()

func resync_tracks(force: bool = false):
	if music == null: return
	for track: AudioStreamPlayer in music.get_children():
		if force or SoundBoard.is_track_desynced(track, music):
			track.seek(music.get_playback_position())

func _unhandled_key_input(e: InputEvent):
	if not is_node_ready() or not e.pressed: return
	match e.keycode:
		KEY_ENTER:
			if can_pause and not get_tree().paused:
				get_tree().paused = true
				var pausemenu = load("res://raven/game/menus/pause.tscn").instantiate()
				pausemenu.layer = 5
				pausemenu.exit_callback = func():
					autoplay_text.visible = Settings.autoplay
					if Settings.autoplay or Settings.practice:
						points.valid_score = false
					
					for nf: NoteField in strums.get_children():
						nf.set_scroll(Settings.scroll)
						var player_index: int = 1 if Settings.enemy_play else 0
						if nf.get_index() == player_index:
							nf.is_cpu = Settings.autoplay
					
					reset_ui_position()
					reset_combo_group_position()
				add_child(pausemenu)
		KEY_F7: leave(2)

func leave(exit_code: int = -1):
	if exit_code == -1: exit_code = play_manager.play_mode
	if parent != null:
		parent.call_deferred("modchart_call", "on_game_end", [exit_code])
	
	if exit_code != 2 and Settings.show_eval_screen:
		var eval_screen: Control = load("res://raven/game/ui/evaluation_screen.tscn").instantiate()
		eval_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		eval_screen.close_callback = func():
			play_manager.end_play_session(exit_code)
		eval_screen.z_index = 10
		self.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(eval_screen)
	else:
		play_manager.end_play_session(exit_code)

func load_skin():
	if chart != null and chart.metadata.skin != null:
		skin = chart.metadata.skin
	else:
		skin = load("res://raven/resources/ui/normal.tres")
	combo_group.skin = skin
	combo_group.scale *= 0.9
	reset_combo_group_position()

func reset_ui_position():
	match Settings.scroll:
		1:
			health_bar.position.y = 60
			score_text.position.y = health_bar.position.y + 40
		_:
			health_bar.position.y = get_viewport_rect().size.y - 90
			score_text.position.y = health_bar.position.y + 40

func reset_combo_group_position():
	var viewport: = get_viewport_rect().size
	match Settings.judgement_placement:
		0: # World
			combo_group.position = Vector2(viewport.x * 0.03, viewport.y * 0.05)
		1: # HUD
			combo_group.position.x = 200.0 if Settings.enemy_play else viewport.x - 180.0
			match Settings.scroll:
				1: combo_group.position.y = (viewport.y - 630)
				2,3: combo_group.position.y = (viewport.y - 450)
				_: combo_group.position.y = (viewport.y - 150)
#endregion
