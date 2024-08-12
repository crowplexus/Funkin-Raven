extends Node

signal istep_reached(istep: int)
signal ibeat_reached(ibeat: int)
signal ibar_reached (ibar : int)

signal fstep_reached(fstep: float)
signal fbeat_reached(fbeat: float)
signal fbar_reached (fbar : float)

const TIME_CHANGE_TEMPLATE: Dictionary = {
	"bpm": 100.0,
	"beat_time": null,
	"time_stamp": -INF,
	"beat_tuplets": [4, 4, 4, 4],
	"signature_num": 4,
	"signature_den": 4,
}

var time: float = 0.0
func get_time_with_offset(custom_time: float = time) -> float:
	return custom_time + (Preferences.beat_offset * 0.001)

var length: float = 1.0
var time_changes: Array[Dictionary] = []
var current_time_change: int:
	set(nt):
		if time_changes.is_empty() or nt > time_changes.size():
			return
		Conductor.bpm = time_changes[nt].bpm
		Conductor.steps_per_beat = time_changes[nt].signature_num
		Conductor.beats_per_bar = time_changes[nt].signature_den
		current_time_change = nt

var rate: float = 1.0:
	set(new_rate):
		Engine.time_scale = new_rate
		AudioServer.playback_speed_scale = new_rate
		rate = new_rate

var bpm: float = 100.0:
	set(new_bpm):
		crotchet = (60 / new_bpm)
		semiquaver = crotchet / steps_per_beat
		semibreve = crotchet * beats_per_bar
		bpm = new_bpm

var crotchet: float = 0.0 # Beat
var semiquaver: float = 0.0 # Step
var semibreve: float = 0.0 # Bar

var rows_per_beat: int = 48
var rows_per_bar: int:
	get: return rows_per_beat * beats_per_bar

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
var _previous_fstep: float = 0.0
var _previous_istep: int = 0


func _to_string() -> String:
	return "Time: %s | Music Delta: %s\nStep: %s | Beat: %s | Bar: %s\nBPM: %s | Playback Rate: %s | Time Signature %s/%s" % [
		str(time).pad_decimals(2), str(_previous_time - time).pad_decimals(2),
		str(fstep).pad_decimals(2), str(fbeat).pad_decimals(2), str(fbar).pad_decimals(2),
		str(bpm), str(rate).pad_decimals(2), str(steps_per_beat), str(beats_per_bar),
	]


func update(delta_time: float) -> void:
	time = delta_time
	var beat_dt: float = (bpm / 60.0) * (time - _previous_time)
	fstep += beat_dt * steps_per_beat
	fbeat += beat_dt # oh hi hello :D
	fbar  += beat_dt / beats_per_bar
	# call step hit and stuff
	if _previous_fstep < fstep: # float
		fstep_reached.emit(fstep)
		if fmod(fstep, 4) == 0: fbeat_reached.emit(fbeat)
		if fmod(fbeat, 4) == 0: fbar_reached.emit(fbar)
		_previous_fstep = fstep

	if _previous_istep < istep: # int
		istep_reached.emit(istep)
		if istep % 4 == 0: ibeat_reached.emit(ibeat)
		if ibeat % 4 == 0: ibar_reached.emit(ibar)
		_previous_istep = istep
	_previous_time = time


#region Utility Functions

## Resets all the important values and data in the conductor.
func reset() -> void:
	length = 1.0
	current_time_change = 0
	time_changes.clear()
	set_time(0.0)

## Sets the beat, and step values to new ones based on the given time.
func set_time(new_time: float, with_offset: bool = false) -> void:
	if with_offset: new_time += (Preferences.beat_offset * 0.001)
	time = new_time
	_previous_time = new_time
	reset_beats(new_time)

## Resets the beat, step and bar values to match a specific timeframe
func reset_beats(new_time: float) -> void:
	fbeat = Conductor.time_to_beat(new_time)
	fstep = Conductor.time_to_step(new_time)
	fbar  = Conductor.time_to_bar(new_time)
	_previous_istep = floori(fstep)
	_previous_fstep = fstep

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

## Utility function to sort through the time changes array
func sort_time_changes(changes_to_sort: Array[Dictionary] = []) -> void:
	if changes_to_sort.is_empty():
		changes_to_sort = Conductor.time_changes
	changes_to_sort.sort_custom(func(a: Dictionary, b: Dictionary):
		return a.time_stamp < b.time_stamp)

## Utility function to apply a time change dictionary.
func apply_time_change(tc: Dictionary) -> void:
	Conductor.current_time_change = time_changes.find(tc)
	#print_debug("time change applied, current time change is ", Conductor.current_time_change)
	#print_debug("bpm applied from time change, current bpm is ", Conductor.bpm)

#stolen from TE thank you nebula
func beat_to_row(beat: float) -> int:
	return round(beat * Conductor.rows_per_beat)

func row_to_beat(row: int) -> float:
	return row / Conductor.rows_per_beat

## Converts beat time to seconds.
func beat_to_time(ctime: float, cbpm: float = -1) -> float:
	if cbpm == -1: cbpm = Conductor.bpm
	return (ctime * 60.0) / cbpm

## Converts time (in seconds) to beats.
func time_to_beat(ctime: float, cbpm: float = -1) -> float:
	if cbpm == -1: cbpm = Conductor.bpm
	return (ctime * cbpm) / 60.0

## Ditto from [code]beat_to_time[/code] but converts to steps
func step_to_time(ctime: float, cbpm: float = -1, spb: int = 0) -> float:
	if spb == 0: spb = Conductor.steps_per_beat
	return beat_to_time(ctime, cbpm) / spb

## Ditto from [code]time_to_beat[/code] but converts to steps
func time_to_step(ctime: float, cbpm: float = -1, spb: int = 0) -> float:
	if spb == 0: spb = Conductor.steps_per_beat
	return time_to_beat(ctime, cbpm) * spb

## Ditto from [code]beat_to_time[/code] but converts to bars/measures
func bar_to_time(ctime: float, cbpm: float = -1, bpb: int = 0) -> float:
	if bpb == 0: bpb = Conductor.beats_per_bar
	return beat_to_time(ctime, cbpm) / bpb

## Ditto from [code]time_to_beat[/code] but converts to bars/measures
func time_to_bar(ctime: float, cbpm: float = -1, bpb: int = 0) -> float:
	if bpb == 0: bpb = Conductor.beats_per_bar
	return time_to_beat(ctime, cbpm) / bpb

#endregion
