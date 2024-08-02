extends Node
## This executes nearby events during gameplay.
class_name EventMachine

signal event_fired(id: int)

@export var event_list: Array[ChartEvent] = []
@export var current_event_id: int = 0
var camera_tween_pos: Tween
var camera_tween_zoom: Tween


func _ready() -> void:
	current_event_id = 0
	if Chart.global and event_list.is_empty():
		event_list = Chart.global.events.duplicate()
	if not event_list.is_empty():
		for ev: ChartEvent in event_list:
			ev.fired = false
		if not Conductor.fstep_reached.is_connected(event_step):
			Conductor.fstep_reached.connect(event_step)


func _exit_tree() -> void:
	if Conductor.fstep_reached.is_connected(event_step):
		Conductor.fstep_reached.disconnect(event_step)


func event_step(fstep: float) -> void:
	# return if it's at the end of the list
	if event_list.size() <= current_event_id:
		return
	var event: ChartEvent = event_list[current_event_id]
	var estep: float = (event.step + event.delay)
	if fstep >= estep and not event.fired:
		call_event(current_event_id)
		current_event_id += 1


func call_event(id: int) -> void:
	var e: ChartEvent = event_list[id]
	match e.name:
		"FocusCamera":
			var stage: StageBG = get_parent().stage
			if not is_instance_valid(stage):
				push_warning("(FocusCamera Event) - No stage available, a stage is needed in order to get characters from it in order to focus the camera on said character.")
				return

			var cam_pos: Vector2 = Vector2.ZERO
			if "x" in e.values: cam_pos.x = float(e.values.x)
			if "y" in e.values: cam_pos.y = float(e.values.y)

			var c: Camera2D = get_viewport().get_camera_2d()
			if c:
				match e.values.char:
					_ when int(e.values.char) != -1:
						var t: = stage.get_node("player%s" % str(e.values.char+1))
						if t:
							#print_debug("(FocusCamera) Focusing on %s" % t.display_name)
							var old_pos: Vector2 = cam_pos
							cam_pos = t.global_position
							if t is Character: cam_pos += t.camera_offset
							cam_pos += old_pos

				match e.values.ease:
					"CLASSIC":
						c.position_smoothing_enabled = true
						c.global_position = cam_pos
					"INSTANT":
						c.position_smoothing_enabled = false
						c.global_position = cam_pos
					_:
						if e.values.duration == 0:
							c.position_smoothing_enabled = false
							c.global_position = cam_pos
						else:
							c.position_smoothing_enabled = true
							if camera_tween_pos:
								camera_tween_pos.stop()
							var easev: String = str(e.values.ease)
							var dur_steps: float = Conductor.semiquaver * e.values.duration
							var _easing: Tween.EaseType = convert_flixel_tween_ease(easev)
							var _trans: Tween.TransitionType = convert_flixel_tween_trans(easev)
							camera_tween_pos = create_tween().set_ease(_easing).set_trans(_trans)
							camera_tween_pos.tween_property(c, "global_position", cam_pos, dur_steps)

		"ZoomCamera":
			var stage: StageBG = get_parent().stage
			if not is_instance_valid(stage):
				push_warning("(ZoomCamera Event) - No stage available, a stage is needed in order to get characters from it in order to zoom the camera.")
				return

			var c: Camera2D = get_viewport().get_camera_2d()
			if c:
				var duration: float = float(e.values.duration)
				var target_zoom: Vector2 = stage.initial_camera_zoom
				var direct_mode: bool = str(e.values.mode) == "direct"
				target_zoom = Vector2(e.values.zoom, e.values.zoom)
				if not direct_mode:
					target_zoom *= stage.initial_camera_zoom

				match str(e.values.ease):
					"INSTANT":
						stage.current_camera_zoom = target_zoom
					_:
						if camera_tween_zoom:
							camera_tween_zoom.stop()
						var easev: String = str(e.values.ease)
						var dur_steps: float = Conductor.semiquaver * duration
						var _easing: Tween.EaseType = convert_flixel_tween_ease(easev)
						var _trans: Tween.TransitionType = convert_flixel_tween_trans(easev)
						camera_tween_zoom = create_tween().set_ease(_easing).set_trans(_trans)
						camera_tween_zoom.tween_property(stage, "current_camera_zoom", target_zoom, dur_steps)

		"PlayAnimation":
			var stage: StageBG = get_parent().stage
			if not is_instance_valid(stage):
				push_warning("(PlayAnimation Event) - No stage available, a stage is needed in order to get characters from it in order to make said character play an animation.")
				return
			if "target" in e.values:
				var player: int = 0
				match str(e.values.target).to_snake_case():
					"bf", "boyfriend", "player1", "1": player = 1
					"dad", "opponent", "enemy", "player2", "2": player = 2
					"gf", "girlfriend", "spectator", "crowd", "dj", "player3", "3": player = 3
				var t: = stage.get_node("player%s" % player)
				if t and t is Character:
					t.play_animation(e.values.anim, "force" in e.values and e.values.force == true)
					t.idle_cooldown = 0.8 * Conductor.semibreve
					t.animation_context = 3
		# Custom Event
		_ when not e.custom_func.is_null():
			e.custom_func.call()
	e.fired = true
	event_fired.emit(id)


func convert_flixel_tween_ease(v: String) -> Tween.EaseType:
	if v.ends_with("Out"): return Tween.EASE_OUT
	if v.ends_with("InOut"): return Tween.EASE_IN_OUT
	if v.ends_with("OutIn"): return Tween.EASE_OUT_IN
	return Tween.EASE_IN


func convert_flixel_tween_trans(v: String) -> Tween.TransitionType:
	match v:
		"sineIn", "sineOut", "sineInOut", "sineOutIn":
			return Tween.TRANS_SINE
		"cubeIn", "cubeOut", "cubeInOut", "cubeOutIn":
			return Tween.TRANS_CUBIC
		"quadIn", "quadOut", "quadInOut", "quadOutIn":
			return Tween.TRANS_QUAD
		"quartIn", "quartOut", "quartInOut", "quartOutIn":
			return Tween.TRANS_QUART
		"quintIn", "quintInOut", "quintInOut", "quintOutIn":
			return Tween.TRANS_QUINT
		"expoIn", "expoOut", "expoInOut", "expoOutIn":
			return Tween.TRANS_EXPO
		"smoothStepIn", "smoothStepOut", "smoothStepInOut", "smoothStepOutIn":
			return Tween.TRANS_SPRING # i think?
		"elasticIn", "elasticOut", "elasticInOut", "elasticOutIn":
			return Tween.TRANS_ELASTIC
		_: # default to linear
			return Tween.TRANS_LINEAR
