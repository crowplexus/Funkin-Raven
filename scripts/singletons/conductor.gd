extends Node

signal step_reached(step: int)
signal beat_reached(beat: int)
signal bar_reached (bar : int)

const TIME_CHANGE_TEMPLATE: Dictionary = {
	"bpm": 100.0,
	"beat_time": null,
	"time_stamp": -INF,
	"beat_tuplets": [4, 4, 4, 4],
	"signature_num": 4,
	"signature_den": 4,
}

var active: bool = true

var time: float = 0.0
var time_changes: Array[Dictionary] = []
var current_time_change: int = 0

var bpm: float = 100.0:
	set(new_bpm):
		crotchet = (60 / new_bpm)
		semiquaver = crotchet / steps_per_beat
		semibreve = crotchet * beats_per_bar
		bpm = new_bpm

var crotchet: float = 0.0 # Beat
var semiquaver: float = 0.0 # Step
var semibreve: float = 0.0 # Bar

var steps_per_beat: int = 4
var beats_per_bar: int = 4

var ibeat: int = 0:
	get: return floori(fbeat)
var istep: int = 0:
	get: return floori(fstep)
var ibar: int = 0:
	get: return floori(fbar)

var fbeat: float = 0.0
var fstep: float = 0.0
var fbar: float = 0.0

var _previous_time: float = 0.0
var _previous_istep: int = 0


func _process(_delta: float) -> void:
	if not active:
		return

	var song_dt: float = time - _previous_time
	var beat_dt: float = (60.0 / bpm) * song_dt

	if istep > _previous_istep:
		step_reached.emit(istep)
		if istep % 4 == 0: beat_reached.emit(ibeat)
		if ibeat % 4 == 0: bar_reached.emit(ibar)
		_previous_istep = istep

	fstep += beat_dt * steps_per_beat
	fbeat += beat_dt # oh hi hello :D
	fbar  += beat_dt / beats_per_bar
	_previous_time = time

#region Utility Functions

## Converts a Time Change from Base Game (0.3) to the raven format.
func time_change_from_vanilla(tc: Dictionary) -> Dictionary:
	var new_tc: Dictionary = Conductor.TIME_CHANGE_TEMPLATE.duplicate()
	if "t" in tc: new_tc.time_stamp = tc["t"]
	if "b" in tc: new_tc.beat_time = tc["b"]
	if "bpm" in tc: new_tc.bpm = tc["bpm"]
	if "n" in tc: new_tc.signature_num = tc["n"]
	if "d" in tc: new_tc.signature_den = tc["d"]
	if "bt" in tc: new_tc.beat_tuples = tc["bt"]
	return new_tc

## Resets all the important values and data in the conductor.
func reset() -> void:
	time_changes.clear()
	current_time_change = 0
	_previous_time = 0.0
	_previous_istep = 0
	fbeat = 0.0
	fstep = 0.0
	fbar  = 0.0

## Utility function to sort through the time changes array
func sort_time_changes(changes_to_sort: Array[Dictionary] = []) -> void:
	if changes_to_sort.is_empty():
		changes_to_sort = Conductor.time_changes

	changes_to_sort.sort_custom(func(a: Dictionary, b: Dictionary):
		return a.time_stamp < b.time_stamp)

## Utility function to apply a given time change.
func apply_time_change(tc: Dictionary) -> void:
	# TODO: more
	if "bpm" in tc: Conductor.bpm = tc.bpm
	Conductor.current_time_change = time_changes.find(tc)
	print_debug("time change applied, current time change is ", Conductor.current_time_change)
	print_debug("bpm applied from time change, current bpm is ", Conductor.bpm)

## Converts beat time to seconds.
func beat_to_time(ctime: float, cbpm: float = -1) -> float:
	if cbpm == -1: cbpm = Conductor.bpm
	return (ctime * 60.0) / cbpm

## Converts time (in seconds) to beats.
func time_to_beat(ctime: float, cbpm: float = -1) -> float:
	if cbpm == -1: cbpm = Conductor.bpm
	return (ctime * cbpm) / 60.0

## Ditto from [code]beat_to_time[/code] but converts to steps
func step_to_time(ctime: float, cbpm: float = -1, spb: int = 4) -> float:
	return beat_to_time(ctime, cbpm) / spb

## Ditto from [code]time_to_beat[/code] but converts to steps
func time_to_step(ctime: float, cbpm: float = -1, spb: int = 4) -> float:
	return time_to_beat(ctime, cbpm) * spb

## Ditto from [code]beat_to_time[/code] but converts to bars/measures
func bar_to_time(ctime: float, cbpm: float = -1, bpb: int = 4) -> float:
	return beat_to_time(ctime, cbpm) / bpb

## Ditto from [code]time_to_beat[/code] but converts to bars/measures
func time_to_bar(ctime: float, cbpm: float = -1, bpb: int = 4) -> float:
	return time_to_beat(ctime, cbpm) / bpb

#endregion
