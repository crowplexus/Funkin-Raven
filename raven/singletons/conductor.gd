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
		crotchet = (60.0 / bpm)
		semiquaver = crotchet / steps_per_beat
		semibreve = crotchet * beats_per_bar

## "crochet" -- that was a mispelling.
var crotchet: float = (60.0 / bpm)
## "step_crochet" -- this is the correct naming.
var semiquaver: float = crotchet / steps_per_beat
## "bar/measure_crochet" -- this is the correct naming.
var semibreve: float = crotchet * beats_per_bar

var crotchet_mult: float:
	get: return (bpm / 60.0)
var semiq_mult: float:
	get: return crotchet / steps_per_beat
var semib_mult: float:
	get: return crotchet * beats_per_bar

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

func _ready() -> void: _reset()
func _reset(also_do_signals: bool = true) -> void:
	time = 0.0
	_prev_time = 0.0
	stepf = 0.0
	beatf = 0.0
	barf = 0.0
	_steps_passed.clear()
	active = false
	if also_do_signals:
		reset_signals()

func reset_signals() -> void:
	for connected: Dictionary in on_step.get_connections():
		on_step.disconnect(connected["callable"])
	for connected: Dictionary in on_beat.get_connections():
		on_beat.disconnect(connected["callable"])
	for connected: Dictionary in on_bar .get_connections():
		on_bar .disconnect(connected["callable"])

func _process(_delta: float) -> void:
	if active: # and time >= 0.0:
		# *
		var bdt: float = crotchet_mult * (time - _prev_time)

		if not _steps_passed.has(step):
			if floori(stepf) % 1 == 0:
				on_step.emit(step)
				Tools.deffered_scene_call("on_step", [step])
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

#region Utility Functions
func beat_to_time(ctime: float, cbpm: float = -1) -> float:
	if cbpm == -1: cbpm = Conductor.bpm
	return (ctime * 60.0) / cbpm

func time_to_beat(ctime: float, cbpm: float = -1) -> float:
	if cbpm == -1: cbpm = Conductor.bpm
	return (ctime * cbpm) / 60.0

func step_to_time(ctime: float, cbpm: float = -1, spb: int = 4) -> float:
	return beat_to_time(ctime, cbpm) / spb
func time_to_step(ctime: float, cbpm: float = -1, spb: int = 4) -> float:
	return time_to_beat(ctime, cbpm) * spb
func bar_to_time(ctime: float, cbpm: float = -1, bpb: int = 4) -> float:
	return beat_to_time(ctime, cbpm) / bpb
func time_to_bar(ctime: float, cbpm: float = -1, bpb: int = 4) -> float:
	return time_to_beat(ctime, cbpm) / bpb
#endregion
