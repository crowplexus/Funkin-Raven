extends Menu2D

@onready var bg: Sprite2D = $bg

@onready var buttons: Control = $buttons
@onready var camera: Camera2D = $camera_2d

var in_submenu: bool = false
var _selected: bool = false
var alpha_twns: Array[Tween] = []
var buttons_tween: Tween
var submenu_exit: Callable

func _ready() -> void:
	await RenderingServer.frame_post_draw

	Transition.rect.color = Color.BLACK
	if not SoundBoard.bg_tracks.playing:
		SoundBoard.play_track(load("res://assets/audio/bgm/freakyMenu.ogg"))

	voptions = buttons.get_children()
	alpha_twns.resize(voptions.size())

	update_selection()

func update_selection(new: int = 0) -> void:
	super(new)
	if new != 0: SoundBoard.play_sfx(SCROLL_SOUND)
	for i: int in voptions.size():
		var bt: = voptions[i] as AnimatedSprite2D
		if in_submenu and bt.name != "donate":
			if i == selected: bt.scale = Vector2(0.8, 0.8)
			elif bt.scale != Vector2.ONE: bt.scale = Vector2.ONE
		bt.play("basic" if i != selected else "white")

	camera.global_position.y = (bg.global_position.y - 5) + (10 * selected)

func _unhandled_key_input(e: InputEvent) -> void:
	if _selected or not e.pressed: return
	super(e)

	if e.is_action_pressed("ui_accept"):
		_selected = true
		SoundBoard.play_sfx(CONFIRM_SOUND)

		if Settings.flashing_lights and not Settings.skip_transitions:
			Tools.begin_flicker($"bg/magenta", 1.1, 0.15, false)

		for i: int in voptions.size():
			if i == selected:
				continue

			if alpha_twns[i] != null: alpha_twns[i].stop()
			await RenderingServer.frame_post_draw
			alpha_twns[i] = create_tween().set_ease(Tween.EASE_IN_OUT)
			alpha_twns[i].set_trans(Tween.TRANS_SINE)
			tween_or_do(voptions[i], "modulate:a", 0.0, 0.3, alpha_twns[i])

		var bt: = voptions[selected] as AnimatedSprite2D
		var end_vis: bool = bt.name == "play" or bt.name == "options" or bt.name == "donate"
		var inter: float = 0.08 if Settings.flashing_lights else 0.1
		if not Settings.skip_transitions:
			Tools.begin_flicker(bt, 1.0, inter, end_vis, select_callback)
		else:
			if bt.name == "options":
				for i: Tween in alpha_twns:
					if i == null: continue
					i.stop()
			select_callback()

	if e.is_action_pressed("ui_cancel"):
		if in_submenu:
			if submenu_exit != null:
				submenu_exit.call_deferred()
			_default_bttn()
		else:
			_selected = true
			Tools.switch_scene(load("res://raven/menu/title_screen.tscn"))

func select_callback(item_selected: int = -1) -> void:
	if item_selected == -1: item_selected = selected
	submenu_exit = func() -> void: pass

	match voptions[item_selected].name.to_snake_case():
		"story": # Story Mopde
			Tools.switch_scene(load("res://raven/menu/story_menu.tscn"))
		"freeplay": # Freeplay
			Tools.switch_scene(load("res://raven/menu/freeplay.tscn"))
		"options": # Options
			self.process_mode = Node.PROCESS_MODE_DISABLED
			add_child(Tools.get_options_window())
			_default_bttn()
		_: # Anything else
			print_debug("not implemented.")
			_default_bttn()

func _default_bttn() -> void:
	if buttons_tween != null: buttons_tween.kill()
	for i: AnimatedSprite2D in voptions:
		if i.modulate.a != 1.0:
			buttons_tween = create_tween().set_trans(Tween.TRANS_QUAD)
			tween_or_do(i, "modulate:a", 1.0, 0.5, buttons_tween)
	_selected = false

func tween_or_do(item: CanvasItem, property: String, value: Variant, duration: float, tween: Tween) -> void:
	if Settings.skip_transitions:
		item.set_indexed(property, value)
	else:
		tween.bind_node(item)
		tween.tween_property(item, property, value, duration)
		tween.finished.connect(tween.unreference)
