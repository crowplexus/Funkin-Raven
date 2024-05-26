extends Node

const OPTIONS_WINDOW: PackedScene = preload("res://raven/menu/options/options_window.tscn")

func get_options_window(close_func: Callable = func() -> void: pass) -> Control:
	var options: Control = Tools.OPTIONS_WINDOW.instantiate()
	if close_func.is_valid(): options.close_callback = close_func
	options.process_mode = Node.PROCESS_MODE_ALWAYS
	options.z_index = 5
	return options

var SCREEN_SIZE: Vector2 = Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height")
)

func _ready() -> void:
	PhysicsServer2D.set_active(false)
	PhysicsServer3D.set_active(false)
	Highscore._reset_judgements()
	# makes the game size mathematically the same everywhere!
	var scale: float = DisplayServer.screen_get_size().y / 720
	get_window().size = Vector2i(SCREEN_SIZE.x*scale, SCREEN_SIZE.y*scale)
	get_window().position -= Vector2i(get_window().size.x*0.25, get_window().size.y*0.25)

func exp_lerp(to: float, from: float, speed: float, custom_delta: float = -1) -> float:
	if get_tree().current_scene == null and custom_delta == -1:
		return to

	var delta_time: float = custom_delta
	if custom_delta == -1: delta_time = get_tree().current_scene.get_process_delta_time()
	return lerpf(from, to, exp(-delta_time * speed))

func switch_scene(scene: PackedScene, _skip_transition: bool = false) -> void:
	if Settings.skip_transitions: _skip_transition = true
	if not _skip_transition: await Transition.transition_in()
	get_tree().change_scene_to_packed(scene)
	if not _skip_transition: await Transition.transition_out()

func refresh_scene(_skip_transition: bool = false) -> void:
	if Settings.skip_transitions: _skip_transition = true
	if not _skip_transition: await Transition.transition_in()
	get_tree().reload_current_scene()
	if not _skip_transition: await Transition.transition_out()

func deffered_scene_call(fn: String, args: Array = []) -> void:
	deffered_call(get_tree().current_scene, fn, args)

func deffered_call(node: Node, fn: String, args: Array = []) -> void:
	if node == null: return
	if node.has_method(fn): node.callv(fn, args)

func begin_flicker(node: CanvasItem, duration: float = 1.0, interval: float = 0.04,
	visible_when_finished: bool = false, finished_callback: Callable = func() -> void: pass) -> void:
	####
	if node == null: return
	var twn: Tween = create_tween()
	twn.set_loops(int(duration/interval))
	twn.bind_node(node)

	twn.finished.connect(func() -> void:
		node.modulate.a = 1.0 if visible_when_finished else 0.0
		if finished_callback != null:
			finished_callback.call()
	)

	twn.tween_callback(func() -> void:
		var val: float = 1.0 if node.modulate.a < 1.0 else 0.0
		node.modulate.a = val
	).set_delay(interval)

func float_to_hours(value: float) -> int: return int(value / 3600.0)
func float_to_minute(value: float) -> int: return int(value / 60) % 60
func float_to_seconds(value: float) -> float: return fmod(value, 60)

func format_to_time(value: float) -> String:
	var formatter: String = "%02d:%02d" % [
		float_to_minute(value),
		float_to_seconds(value)
	]

	var hours: int = float_to_hours(value)
	if hours != 0: # append hours if needed
		formatter = ("%02d:" % hours) + formatter
	return formatter
