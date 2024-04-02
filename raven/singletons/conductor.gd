extends Node

signal on_beat(beat: int)
signal on_step(step: int)
signal on_bar(bar: int)

var active: bool = false
var time: float = 0.0
var length: float = 0.0

var rate: float:
	set(v):
		Engine.time_scale = v
		AudioServer.playback_speed_scale = v
		rate = v

var bpm: float = 100.0:
	set(new_bpm):
		bpm = new_bpm
		beatc = (60.0 / bpm)
		stepc = beatc / steps_per_beat
		barc = beatc * beats_per_bar
var beatc: float = (60.0 / bpm)
var stepc: float = beatc / steps_per_beat
var barc: float = beatc * beats_per_bar

var beat_mult: float:
	get: return (bpm / 60.0)
var step_mult: float:
	get: return beatc * steps_per_beat

var steps_per_beat: int = 4
var beats_per_bar: int = 4 

var stepf: float = 0.0
var beatf: float = 0.0
var barf:  float = 0.0

var step: int:
	get: return floori(stepf)
var beat: int:
	get: return floori(beatf)
var bar:  int:
	get: return floori(barf)

var _steps_passed: Array[int] = []
var _prev_time: float = 0.0

func _ready(): _reset()
func _reset(also_do_signals: bool = true):
	time = 0.0
	_prev_time = 0.0
	stepf = 0.0
	beatf = 0.0
	barf = 0.0
	_steps_passed.clear()
	active = false
	if also_do_signals:
		reset_signals()

func reset_signals():
	for connected: Dictionary in on_step.get_connections():
		on_step.disconnect(connected["callable"])
	for connected: Dictionary in on_beat.get_connections():
		on_beat.disconnect(connected["callable"])
	for connected: Dictionary in on_bar .get_connections():
		on_bar .disconnect(connected["callable"])

func _process(_delta: float):
	if active: # and time >= 0.0:
		# *
		var bdt: float = beat_mult * (time - _prev_time)
		var _last_step: int = step
		
		if not _steps_passed.has(step):
			if step > _last_step:
				on_step.emit(step)
				Tools.deffered_scene_call("on_step", [step])
				_last_step = step
			if floori(stepf) % 4 == 0:
				on_beat.emit(beat)
				Tools.deffered_scene_call("on_beat", [beat])
			if floori(beatf) % 4 == 0:
				on_bar.emit(bar)
				Tools.deffered_scene_call("on_bar" , [bar])
			_steps_passed.append(step)
	
		stepf += bdt * steps_per_beat
		beatf += bdt # uhh hello there
		barf  += bdt / beats_per_bar
		_prev_time = time

static func beat_to_time(ctime: float, cbpm: float = -1) -> float:
	if cbpm == -1: cbpm = Conductor.bpm
	return (ctime * 60.0) / cbpm

static func time_to_beat(ctime: float, cbpm: float = -1) -> float:
	if cbpm == -1: cbpm = Conductor.bpm
	return (ctime * cbpm) / 60.0

static func step_to_time(ctime: float, cbpm: float = -1, spb: int = 4) -> float: return beat_to_time(ctime, cbpm) / spb
static func time_to_step(ctime: float, cbpm: float = -1, spb: int = 4) -> float: return time_to_beat(ctime, cbpm) * spb
static func bar_to_time(ctime: float, cbpm: float = -1, bpb: int = 4) -> float: return beat_to_time(ctime, cbpm) / bpb
static func time_to_bar(ctime: float, cbpm: float = -1, bpb: int = 4) -> float: return time_to_beat(ctime, cbpm) / bpb
