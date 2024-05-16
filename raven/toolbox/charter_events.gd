extends ColorRect

class EventNote extends Sprite2D:
	var data:Chart.EventData

var event_tex: Texture2D = preload("res://assets/ui/eventNote.png")
@onready var note_board: ColorRect = $"../board"
@onready var strum: Sprite2D = $strum
@onready var name_label: Label = $name_label
var name_tmr: float = 0.0
var anim_time:float = 5.0 / 24.0
var event_list:Array[Chart.EventData]
var cur_event:int = 0

func on_ready() -> void:
	event_list = PlayField.chart.events.duplicate()
	spawn_events(false)
	update()

func spawn_events(backward:bool = false) -> void:
	if event_list.size() <= 0: return

	var forward_range: float = Conductor.crotchet * 4 * note_board.zoom + 0.001
	if backward:
		cur_event -= int(cur_event == event_list.size())
		for event:EventNote in strum.get_children():
			if event.data.time - Conductor.time < forward_range: continue
			event.queue_free()
		while cur_event >= 0 and cur_event < event_list.size() and event_list[cur_event].time - Conductor.time >= -Conductor.crotchet * note_board.zoom:
			var unspawn:Chart.EventData = event_list[cur_event]
			add_event(unspawn)
			cur_event -= 1
		cur_event += int(cur_event < 0)
	else:
		while cur_event < event_list.size() and event_list[cur_event].time - Conductor.time < forward_range:
			var unspawn:Chart.EventData = event_list[cur_event]
			add_event(unspawn)
			cur_event += 1

func _process(delta: float) -> void:
	anim_time += delta
	strum.frame = floori(0.0 if anim_time >= 5.0 / 24.0 else minf(anim_time * 24.0 + 1.0, 3.0))

	name_tmr -= delta * 2.0
	name_label.modulate.a = minf(name_tmr, 1.0)
	name_label.position.x = -226.0 - 7.5 * maxf(name_tmr - 2.75, 0.0) * 4.0

func update() -> void:
	var delete_window:float = Conductor.crotchet * note_board.zoom
	for event:EventNote in strum.get_children():
		event.position.y = note_board.note_spacing * (Conductor.time_to_beat(event.data.time) - Conductor.beatf)
		var old_mod: float = event.modulate.a
		event.modulate.a = 1.0

		if event.data.time - Conductor.time < -delete_window:
			event.queue_free()

		elif event.data.time < Conductor.time:
			if Conductor.active and old_mod == 1.0:
				anim_time = 0.0
				name_tmr = 3.0
				name_label.text = (
					event.data.name +
					"\n" + "Values: " + str(event.data.args) +
					"\n" + "Time: %s" % event.data.time
				)
			event.modulate.a = 0.6

func add_event(unspawn:Chart.EventData) -> EventNote:
	var event_name: = "Event" + str(cur_event) + "_0" # originally for debugging but can also fix duping
	if strum.has_node(event_name): return null

	var event:EventNote = EventNote.new()
	event.texture = event_tex
	event.data = unspawn
	strum.add_child(event)
	event.name = event_name
	return event
