extends Node2D

@onready var ui_layer: CanvasLayer = $"ui_layer"
@onready var playfield: PlayField = $"ui_layer/playfield"
@onready var camera: Camera2D = $"camera_2d"

var stage: StageBG
var event_list: Array[Chart.EventData] = []
var event_index: int = 0

var modcharts: Array[Modchart] = []

var start_cutscene: Callable
var ending_cutscene: Callable

var _player_index: int = 2 if Settings.enemy_play else 1
var _has_events: bool = false
var _can_die: bool = false

func _ready() -> void:
	await RenderingServer.frame_post_draw

	load_stage()
	if not Settings.hide_characters: load_characters()
	reset_health_bar_colors()

	# PREPARE THE NOTE SPAWNER #
	if PlayField.chart != null:
		event_list = PlayField.chart.events.duplicate()
		_has_events = event_list.size() > 0

	camera.zoom = stage.camera_zoom
	camera.position_smoothing_speed = 3.0 * stage.camera_speed
	# Set start and ending cutscenes here (so modcharts can change it)
	start_cutscene = playfield.countdown
	ending_cutscene = playfield.leave
	playfield.default_scale = stage.hud_zoom

	load_modcharts([
		"res://assets/data/scripts/",
		"user://scripts/",
		"res://assets/data/charts/%s/scripts/" % playfield.song_data.folder,
		"user://songs/%s/scripts/" % playfield.song_data.folder,
	])
	_can_die = has_node("player%s" % str(_player_index))

	for i: Node in get_children():
		if i.has_method("on_step"): Conductor.on_step.connect(i.on_step)
		if i.has_method("on_beat"): Conductor.on_beat.connect(i.on_beat)
		if i.has_method("on_bar" ): Conductor.on_bar.connect(i.on_bar)

	start_cutscene.call()

func _exit_tree() -> void:
	for i: Node in get_children():
		if i.has_method("on_step"): Conductor.on_step.disconnect(i.on_step)
		if i.has_method("on_beat"): Conductor.on_beat.disconnect(i.on_beat)
		if i.has_method("on_bar" ): Conductor.on_bar.disconnect(i.on_bar)

func _process(_delta: float) -> void:
	if Settings.camera_zooms and camera.zoom != Vector2.ONE:
		camera.zoom = Vector2(
			Tools.exp_lerp(camera.zoom.x, stage.camera_zoom.x, 15),
			Tools.exp_lerp(camera.zoom.y, stage.camera_zoom.y, 15)
		)

	if playfield.health <= 0 and not Settings.practice:
		kill_player()

	while _has_events and event_index < event_list.size():
		var event: Chart.EventData = event_list[event_index]
		if event.time > Conductor.time: break
		do_event(event.name, event.args)
		event_index += 1

func kill_player() -> void:
	if not _can_die: return
	var dead: bool = get_node("player%s" % _player_index).try_dying()
	if dead:
		modchart_call("on_death")
		PlayField.death_count += 1
		$ui_layer.visible = false

func do_event(ev_name: StringName, ev_args: Array) -> void:
	match ev_name:
		"Camera Pan":
			var player: Character = get_node("player%s" % ev_args[0]) as Character
			if player != null:
				camera.position = player.position + player.camera_offset
		"BPM Change":
			var prev: float = Conductor.bpm
			Conductor.bpm = float(ev_args[0])
			print_debug("BPM Changed,",Conductor.bpm,",Previous was ",prev)

	modchart_call("on_event", [ev_name, ev_args])

func load_stage() -> void:
	var is_valid: bool = PlayField.chart != null and PlayField.chart.stage_bg != null
	if Settings.hide_stage or not is_valid:
		stage = StageBG.new()
	elif is_valid:
		stage = PlayField.chart.stage_bg.instantiate()
	add_child(stage)
	move_child(stage, 1)

func load_characters() -> void:
	if PlayField.chart == null:
		return

	var id: int = 0
	for i: PackedScene in PlayField.chart.chars:
		if i == null:
			continue

		var new_player: Character = i.instantiate() as Character
		if new_player == null:
			continue

		new_player.actor_name = new_player.name
		new_player.name = "player%s" % [id + 1]

		if id == 0: new_player._faces_left = true
		new_player._has_control = id == _player_index -1
		new_player.position = stage.position + stage.position_markers[id] + new_player.position

		if playfield.enable_health and id < 2:
			var icon: Sprite2D = playfield.get_node("health_bar/player%s" % [id+1]) as Sprite2D
			icon.texture = new_player.health_icon

		# this is hacky.
		if playfield.fields.find_child("player%s" % [id + 1]) != null:
			var notefield: NoteField = playfield.fields.get_child(id) as NoteField
			var old_hb: Callable = notefield.hit_behaviour

			notefield.hit_behaviour = func(note: Note) -> void:
				if note == null or (note.was_hit and not note.is_sustain):
					return
				if new_player.animation_context != Character.AnimContext.SPECIAL:
					var force: bool = note.arrow.visible or note.receptor.frame == 0
					var proper_dir: int = note.data.column % new_player.singing_steps.size()

					# TODO: unhardcode this shit later :3
					var suffix: StringName = ""
					if note.is_sustain and new_player.has_hold_anim(proper_dir):
						suffix = new_player.hold_suffix

					new_player.sing(proper_dir, force, suffix)
					new_player.idle_cooldown = (12 * Conductor.semiquaver) + note.data.s_len
				modchart_call("on_note_hit", [note, id+1])
				old_hb.call(note)

			if new_player._has_control:
				var old_mb: Callable = notefield.miss_behaviour
				notefield.miss_behaviour = func(note: Note, column: int) -> void:
					modchart_call("on_note_miss", [note, column, id + 1])
					new_player.miss(column, true)
					old_mb.call(note, column)
		add_child(new_player)
		id += 1

	if has_node("player1") and has_node("player3"): # position gf.
		var p3: = get_node("player3") as Character
		move_child(p3, get_node("player1").get_index()-1 )

func on_step(step: int) -> void:
	modchart_call("on_step", [step])

func on_beat(beat: int) -> void:
	for i: Node in get_children():
		if i is Character and beat % i.dance_interval == 0 and \
			i.animation_context == 0:
			i.dance()
	modchart_call("on_beat", [beat])
	if playfield.enable_zooming and beat % playfield.beats_to_bump == 0:
		camera.zoom += Vector2(0.015, 0.015)

func on_bar(bar: int) -> void:
	modchart_call("on_bar", [bar])

func load_modcharts(paths: PackedStringArray = []) -> void:
	if paths.is_empty(): return

	for path: String in paths:
		if not DirAccess.dir_exists_absolute(path): continue
		for i: String in DirAccess.get_files_at(path):
			if i.get_extension() != "gd": continue
			modcharts.append(Modchart.create(
				path + i, playfield.song_data, self)
			)
			add_child(modcharts.back())

func modchart_call(fun: String, args: Array = []) -> void:
	for m: Modchart in modcharts:
		m.propagate_call(fun, args)

func reset_health_bar_colors() -> void:
	if playfield == null: return
	var hb: = playfield.health_bar as ProgressBar
	if not hb.has_method("set_colors"): return
	hb.set_colors()

	if not has_node("player1") or not has_node("player2"):
		return

	var left: String = "left" if not Settings.enemy_play else "right"
	var right: String = "right" if not Settings.enemy_play else "left"

	match Settings.health_bar_color_style:
		0: # By Character
			hb.set(left+"_color", get_node("player2").health_color)
			hb.set(right+"_color",get_node("player1").health_color)
		1: pass # Red and Lime.
		2: # Red and Player Color
			hb.set(right+"_color", get_node("player1").health_color)
		3: # Enemy Color and Lime
			hb.set(left+"_color",  get_node("player2").health_color)
