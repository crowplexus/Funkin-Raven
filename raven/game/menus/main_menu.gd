extends Menu2D

@onready var bg: Sprite2D = $bg

@onready var buttons: Control = $buttons
@onready var donate: AnimatedSprite2D = $buttons/donate
@onready var options: Array = buttons.get_children()
@onready var camera: Camera2D = $camera_2d

var in_submenu: bool = false
var submenu_exit: Callable

func _ready():
	await RenderingServer.frame_post_draw
	
	Transition.rect.color = Color.BLACK
	if not SoundBoard.bg_tracks.playing:
		SoundBoard.play_track(load("res://assets/audio/bgm/freakyMenu.ogg"))
	
	total_selectors = options.size()
	alpha_twns.resize(total_selectors)
	
	update_selection()

func update_selection(new: int = 0):
	if total_selectors < 2: return
	super(new)
	if new != 0: SoundBoard.play_sfx(SCROLL_SOUND)
	for i in options.size():
		var bt: = options[i] as AnimatedSprite2D
		if in_submenu and bt.name != "donate":
			if i == selected: bt.scale = Vector2(0.8, 0.8)
			elif bt.scale != Vector2.ONE: bt.scale = Vector2.ONE
		bt.play("basic" if i != selected else "white")
	
	camera.global_position.y = (bg.global_position.y - 5) + (10 * selected)

var _selected: bool = false
var alpha_twns: Array[Tween] = []

func _unhandled_key_input(e: InputEvent):
	if _selected or not e.pressed: return
	super(e)
	
	if e.is_action_pressed("ui_accept"):
		_selected = true
		SoundBoard.play_sfx(CONFIRM_SOUND)
		
		if Settings.flashing_lights and not Settings.skip_transitions:
			Tools.begin_flicker($"bg/magenta", 1.1, 0.15, false)
		
		for i: int in options.size():
			if i == selected:
				continue
			
			if alpha_twns[i] != null: alpha_twns[i].stop()
			await RenderingServer.frame_post_draw
			alpha_twns[i] = create_tween().set_ease(Tween.EASE_IN_OUT)
			alpha_twns[i].set_trans(Tween.TRANS_SINE)
			tween_or_do(options[i], "modulate:a", 0.0, 0.3, alpha_twns[i])
		
		var bt: = options[selected] as AnimatedSprite2D
		var end_vis: bool = bt.name == "play" or bt.name == "options" or bt.name == "donate"
		var inter: float = 0.08 if Settings.flashing_lights else 0.1
		if not Settings.skip_transitions:
			Tools.begin_flicker(bt, 1.0, inter, end_vis, select_callback)
		else:
			if bt.name == "options":
				for i in alpha_twns:
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
			Tools.switch_scene(load("res://raven/game/menus/title_screen.tscn"))

func select_callback(item_selected: int = -1):
	if item_selected == -1: item_selected = selected
	submenu_exit = func(): pass
	
	match options[item_selected].name.to_snake_case():
		"play":
			in_submenu = true
			var play: = $"buttons/play"
			
			var _pos_twn: Tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
			tween_or_do(play, "position:y", play.position.y - 100, 0.3, _pos_twn)

			play.modulate.a = 0.7
			play.play("basic")
			play.frame = 0
			
			options = [ $"buttons/play/anti_flicker/story", $"buttons/play/anti_flicker/freeplay" ]
			total_selectors = options.size()
				
			for i in options:
				if not i.visible: i.visible = true
				
				i.modulate.a = 0.0
				var _mod_a_twn: Tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
				_mod_a_twn.finished.connect(func(): _selected = false)
				tween_or_do(i, "modulate:a", 1.0, 0.5, _mod_a_twn)
				if Settings.skip_transitions and i.get_index() == options.size()-1:
					_selected = false
			
			submenu_exit = func():
				_selected = true
				in_submenu = false
				
				var back_to_menu: = func():
					options = buttons.get_children()
					selected = options.find(play)
					total_selectors = options.size()
					_default_bttn()
					update_selection()
				
				for i in options:
					if Settings.skip_transitions:
						i.modulate.a = 0.0
						continue
					var twn: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
					tween_or_do(i, "modulate:a", 0.0, 0.5, twn)
				
				play.modulate.a = 1.0
				var _back_to_place: Tween = create_tween().set_trans(Tween.TRANS_CUBIC)
				_back_to_place.finished.connect(back_to_menu)
				tween_or_do(play, "position:y", play.position.y + 100, 0.3, _back_to_place)
				if Settings.skip_transitions:
					await get_tree().create_timer(0.05).timeout
					back_to_menu.call()
			
			update_selection()
			
		"story": # Story Mopde
			Tools.switch_scene(load("res://raven/game/menus/story_menu.tscn"))
		"freeplay": # Freeplay
			Tools.switch_scene(load("res://raven/game/menus/freeplay.tscn"))
		"donate": # Donate, Kickstarter
			if not in_submenu:
				in_submenu = true
				submenu_exit = func():
					trigger_donate_event(true)
				trigger_donate_event()
			else:
				# Itch.io Page
				OS.shell_open("https://itch.io/queue/c/1525920/friday-night-funkin?game_id=792778")
				trigger_donate_event(true)
		"kickstarter":
			OS.shell_open("https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game")
			trigger_donate_event(true)
		"options": # Options
			self.process_mode = Node.PROCESS_MODE_DISABLED
			add_child(Tools.get_options_window())
			_default_bttn()
		_: # Anything else
			print_debug("not implemented.")
			_default_bttn()

var buttons_tween: Tween
func _default_bttn():
	if buttons_tween != null: buttons_tween.kill()
	for i: AnimatedSprite2D in options:
		if i.modulate.a != 1.0:
			buttons_tween = create_tween().set_trans(Tween.TRANS_QUAD)
			tween_or_do(i, "modulate:a", 1.0, 0.5, buttons_tween)
	_selected = false

func trigger_donate_event(out: bool = false):
	var kickstarter: = donate.get_child(0).get_child(0) as AnimatedSprite2D
	if kickstarter.modulate.a != 1.0: kickstarter.modulate.a = 1.0
	
	if not out:
		var twn: Tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
		twn.set_parallel(true)
		
		tween_or_do(donate, "position:x", donate.position.x - 300, 0.5, twn)
		tween_or_do(kickstarter, "position:x", kickstarter.position.x + 300, 0.5, twn)
		
		tween_or_do(kickstarter, "visible", true, 0.5, twn)
		if not Settings.skip_transitions:
			await get_tree().create_timer(0.5).timeout
		_selected = false
		
		options = [donate, kickstarter]
		total_selectors = options.size()
	else:
		var twn: Tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
		twn.set_parallel(true)
		
		tween_or_do(donate, "position:x", donate.position.x + 300, 0.5, twn)
		tween_or_do(kickstarter, "position:x", kickstarter.position.x - 300, 0.5, twn)
		
		tween_or_do(kickstarter, "visible", false, 0.5, twn)
		if not Settings.skip_transitions:
			await get_tree().create_timer(0.5).timeout
		_selected = false
		
		in_submenu = false
		
		options = buttons.get_children()
		total_selectors = options.size()
		_default_bttn()
	
	selected = options.find(donate)
	update_selection()

func tween_or_do(item: CanvasItem, property: String, value: Variant, duration: float, tween: Tween):
	if Settings.skip_transitions:
		item.set_indexed(property, value) 
	else:
		tween.bind_node(item)
		tween.tween_property(item, property, value, duration)
		tween.finished.connect(tween.unreference)
