extends Node2D

@onready var ui_layer: CanvasLayer = $ui_layer
@onready var playfield: PlayField = $ui_layer/playfield
@onready var camera: Camera2D = $camera_2d

var stage: StageBG
var event_index: int = 0

var modcharts: Array[Modchart] = []

var start_cutscene: Callable
var ending_cutscene: Callable

var _player_index: int = 2 if Settings.enemy_play else 1
var _has_events: bool = false
var _can_die: bool = false

func _ready():
	await RenderingServer.frame_post_draw
	
	load_stage()
	if not Settings.hide_characters: load_characters()
	
	camera.zoom = stage.camera_zoom
	camera.position_smoothing_speed = 3.0 * stage.camera_speed
	# Set start and ending cutscenes here (so modcharts can change it)
	start_cutscene = playfield.countdown
	ending_cutscene = playfield.leave
	
	if playfield != null:
		if playfield.chart != null and playfield.chart.events.size() > 0:
			_has_events = true

		#playfield.combo_group.reparent(self)
		playfield.default_play_scale = stage.hud_zoom
	
	load_modcharts([
		"res://assets/data/scripts/",
		"user://scripts/",
		"res://assets/data/charts/%s/scripts/" % playfield.song_data.folder,
		"user://songs/%s/scripts/" % playfield.song_data.folder,
	])
	_can_die = has_node("player%s" % str(_player_index))
	
	for i in get_children():
		if i.has_method("on_step"):
			Conductor.on_step.connect(i.on_step)
		if i.has_method("on_beat"):
			Conductor.on_beat.connect(i.on_beat)
		if i.has_method("on_bar" ):
			Conductor.on_bar.connect(i.on_bar)
	
	if playfield != null and Settings.judgement_placement == 0:
		playfield.combo_group.reparent(self)
	
	start_cutscene.call()

func _exit_tree():
	for i in get_children():
		if i.has_method("on_step"):
			Conductor.on_step.disconnect(i.on_step)
		if i.has_method("on_beat"):
			Conductor.on_beat.disconnect(i.on_beat)
		if i.has_method("on_bar" ):
			Conductor.on_bar.disconnect(i.on_bar)

func _process(delta: float):
	if Settings.camera_zooms and camera.zoom != Vector2.ONE:
		camera.zoom = Vector2(
			Tools.lerp_fix(camera.zoom.x, stage.camera_zoom.x, delta, 15),
			Tools.lerp_fix(camera.zoom.y, stage.camera_zoom.y, delta, 15)
		)
	
	if playfield != null and playfield.health <= 0 and not Settings.practice:
		kill_player()
	
	while _has_events and event_index < playfield.event_list.size():
		var event: EventData = playfield.event_list[event_index]
		if event.time > Conductor.time: break
		do_event(event.name, event.args)
		event_index += 1

func kill_player():
	if not _can_die: return
	var dead: bool = get_node("player%s" % _player_index).try_dying()
	modchart_call("on_death")
	if dead:
		PlayField.death_count += 1
		$ui_layer.visible = false

func do_event(ev_name: StringName, ev_args: Array):
	match ev_name:
		"Camera Pan":
			var player: Character = get_node("player%s" % ev_args[0]) as Character
			if player != null:
				camera.position = player.position + player.camera_offset
		
		"BPM Change":
			var prev: float = Conductor.bpm
			Conductor.bpm = float(ev_args[0])
			print_debug("BPM Changed,",Conductor.bpm,",Previous was ", prev)

func load_stage():
	var is_valid: bool = playfield.chart != null and playfield.chart.stage_bg != null
	if is_valid and not Settings.hide_stage:
		stage = playfield.chart.stage_bg.instantiate()
	else:
		stage = StageBG.new()
	add_child(stage)
	move_child(stage, 1)

func load_characters():
	if playfield.chart == null: return
	var id: int = 0
	for i: PackedScene in playfield.chart.chars:
		if i == null: continue
		
		var new_player: Character = i.instantiate() as Character
		new_player.actor_name = new_player.name
		new_player.name = "player%s" % str(id + 1)
		
		if id == 0: new_player._is_real_player = true
		new_player._has_control = id == _player_index -1
		
		new_player.position = stage.position + stage.position_markers[id] + new_player.position
		
		if playfield.enable_health and id < 2:
			var icon: Sprite2D = playfield.get_node("health_bar/player%s"%str(id+1)) as Sprite2D
			icon.texture = new_player.health_icon
		add_child(new_player)
		
		# this is hacky.
		if playfield.strums.find_child("player%s" % str(id + 1)) != null:
			var notefield: NoteField = playfield.strums.get_child(id) as NoteField
			
			var old_hb: Callable = notefield.hit_behavior
			notefield.hit_behavior = func(note: Note):
				if note == null: return
				if new_player.animation_context != Character.AnimContext.SPECIAL:
					new_player.sing(note.data.dir % new_player.singing_steps.size(), true)
					new_player.idle_cooldown = (12 * Conductor.stepc) + note.data.s_len
				modchart_call("on_note_hit", [note, id+1])
				old_hb.call(note)
			
			if new_player._has_control:
				var old_mb: Callable = notefield.miss_behavior
				notefield.miss_behavior = func(note: Note, dir: int):
					modchart_call("on_note_miss", [note, dir, id+1])
					old_mb.call(note, dir)
					new_player.miss(dir, true)
		id += 1
	
	if has_node("player3"): # gf.
		var p3: = get_node("player3") as Character
		move_child(p3, get_node("player1").get_index()-1 )

func on_step(step: int):
	modchart_call("on_step", [step])

func on_beat(beat: int):
	for i in get_children():
		if i is Character and beat % i.dance_interval == 0 and \
			i.animation_context == 0:
			i.dance()
	modchart_call("on_beat", [beat])
	if playfield != null:
		if playfield.enable_zooming and beat % playfield.beats_to_bump == 0:
			camera.zoom += Vector2(0.015, 0.015)

func on_bar(bar: int):
	modchart_call("on_bar", [bar])

func load_modcharts(paths: PackedStringArray = []):
	if paths.is_empty(): return
	
	for path: String in paths:
		if not DirAccess.dir_exists_absolute(path): continue
		for i: String in DirAccess.get_files_at(path):
			if i.get_extension() != "gd": continue
			modcharts.append(Modchart.create(
				path + i, playfield.song_data, self)
			)
			add_child(modcharts.back())

func modchart_call(fun: String, args: Array = []):
	for m: Modchart in modcharts:
		m.propagate_call(fun, args)
