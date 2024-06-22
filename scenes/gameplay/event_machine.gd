extends Node
## Event Hook for gameplay,
## This simply executes nearby events during gameplay;
class_name EventMachine

signal event_fired(id: int)

@export var event_list: Array[ChartEvent] = []
@export var current_event_id: int = 0


func call_event(id: int) -> void:
	var e: ChartEvent = event_list[id]
	match e.name:
		"FocusCamera", "Change Camera Focus":
			var stage: StageBG = get_parent().stage
			if not is_instance_valid(stage):
				push_warning("(FocusCamera Event) - No stage available, a stage is needed in order to get characters from it in order to focus the camera on said character.")

			var cam_pos: Vector2 = Vector2.ZERO
			if "x" in e.values: cam_pos.x = float(e.values.x)
			if "y" in e.values: cam_pos.y = float(e.values.y)

			var c: Camera2D = get_viewport().get_camera_2d()
			if is_instance_valid(c):
				var duration: float = 4.0
				match e.values.char:
					_:
						var t: Character = stage.get_node("player%s" % str(e.values.char)) as Character
						if is_instance_valid(t) and is_instance_valid(c):
							#print_debug("(FocusCamera) Focusing on %s" % t.display_name)
							cam_pos += t.global_position + t.camera_offset
							# center? temporary

				match e.values.ease:
					"CLASSIC":
						c.position_smoothing_enabled = true
					"INSTANT":
						c.position_smoothing_enabled = false
					_:

						var easev: String = str(e.values.ease)
						var _step: float = Conductor.semiquaver * duration
						var _easing: Tween.EaseType = convert_flixel_tween_ease(easev)
						var _trans: Tween.TransitionType = convert_flixel_tween_trans(easev)
						c.position_smoothing_enabled = true
				c.global_position = cam_pos

		"PlayAnimation":
			var stage: StageBG = get_parent().stage
			if not is_instance_valid(stage):
				push_warning("(PlayAnimation Event) - No stage available, a stage is needed in order to get characters from it in order to make said character play an animation.")
			if "target" in e.values:
				var player: int = 0
				match str(e.values.target).to_snake_case():
					"bf", "boyfriend", "player1", "1", 1:
						player = 1
					"dad", "opponent", "enemy", "player2", "2":
						player = 2
					"gf", "girlfriend", "spectator", "crowd", "dj", "player3", "3":
						player = 3

				var t: Character = stage.get_node("player%s" % player) as Character
				if is_instance_valid(t):
					t.play_animation(e.values.anim, "force" in e.values and e.values.force == true)
					t.idle_cooldown = 0.8 * Conductor.semibreve
					t.animation_context = 3
		# Custom Event
		_ when not e.custom_func.is_null():
			e.custom_func.call()
	e.fired = true
	event_fired.emit(id)


func _ready() -> void:
	if is_instance_valid(Chart.global):
		event_list = Chart.global.events.duplicate()
	if not event_list.is_empty():
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
