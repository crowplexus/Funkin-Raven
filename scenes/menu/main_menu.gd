extends Node2D

@onready var bg: Sprite2D = $"parallax_node/background"
@onready var magenta: Sprite2D = $"parallax_node/magenta"
@onready var camera: Camera2D = $"camera_2d"
@onready var buttons: Control = $"buttons"

var current_item: CanvasItem
var current_selection: int = 0
var selectable_buttons: Array[CanvasItem] = []
var _done: bool = false

func _ready() -> void:
	for button: CanvasItem in buttons.get_children():
		if is_unselectable(button):
			button.modulate = Color.BLACK
		else:
			selectable_buttons.append(button)
	if not SoundBoard.is_bgm_playing():
		SoundBoard.play_bgm(Globals.MENU_MUSIC, 0.7)
	update_selection()

func _unhandled_input(e: InputEvent) -> void:
	# prevents a bug with moving the mouse which would change selections nonstop
	if _done or e is InputEventMouseMotion:
		return
	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	if ud:
		update_selection(ud)
	if Input.is_action_just_pressed("ui_accept"):
		confirm_selection()

func update_selection(new_sel: int = 0, sound: bool = true) -> void:
	if is_instance_valid(current_item) and current_item is AnimatedSprite2D:
		current_item.play("idle")
	current_selection = wrapi(current_selection + new_sel, 0, selectable_buttons.size())
	current_item = selectable_buttons[current_selection]
	if new_sel != 0 and sound:
		SoundBoard.play_sfx(Globals.MENU_SCROLL_SFX)
	if current_item is AnimatedSprite2D:
		current_item.play("selected")
	if buttons.get_child_count() > 4:
		camera.position.y = current_item.position.y * current_item.scale.y

func confirm_selection() -> void:
	var item: CanvasItem = current_item
	bye_bye_buttons()
	SoundBoard.play_sfx(Globals.MENU_CONFIRM_SFX)
	if Preferences.flashing:
		Globals.begin_flicker(magenta, 1.1, 0.15, false)
		Globals.begin_flicker(item, 1.0, 0.06, false)
	_done = true

	await get_tree().create_timer(1.0).timeout
	match item.name:
		"story":
			Globals.set_node_inputs(self, false)
			Globals.change_scene(load("res://scenes/menu/story_menu.tscn"))
		"freeplay":
			Globals.set_node_inputs(self, false)
			Globals.change_scene(load("res://scenes/menu/freeplay_menu.tscn"))
		"options":
			_done = false
			var ow: Control = Globals.get_options_window()
			ow.close_callback = func() -> void:
				if get_tree().paused:
					get_tree().paused = false
			Transition.add_child(ow)
			get_tree().paused = true
			bye_bye_buttons(true)
		"credits":
			_done = false
			Globals.set_node_inputs(self, false)
			var credits_roll: Node2D = load("res://scenes/menu/credits_roll.tscn").instantiate()
			credits_roll.connect("finished", func() -> void:
				Globals.set_node_inputs(self, true)
				bye_bye_buttons(true)
				_done = false
			)
			add_child(credits_roll)
		"merch":
			_done = false
			OS.shell_open("https://needlejuicerecords.com/pages/friday-night-funkin")
			current_item.self_modulate.a = 1.0
			bye_bye_buttons(true)
		_:
			_done = false
			push_warning("button pressed was ", current_item.name, " but there is no action defined for it")
			current_item.self_modulate.a = 1.0
			bye_bye_buttons(true)

func bye_bye_buttons(coming_back: bool = false) -> void:
	var val: float = 1.0 if coming_back else 0.0
	var duration: float = 0.5 if coming_back else 0.8
	for button: CanvasItem in buttons.get_children():
		var do_tween: bool = button != current_item
		if coming_back and button == current_item:
			do_tween = true
		if do_tween:
			create_tween().set_ease(Tween.EASE_OUT) \
			.tween_property(button, "self_modulate:a", val, duration)

func is_unselectable(item: CanvasItem) -> bool:
	return item and item.has_meta("unselectable") and item.get_meta("unselectable") == true
