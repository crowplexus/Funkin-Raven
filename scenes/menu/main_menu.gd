extends Node2D

@onready var bg: Sprite2D = $"parallax_node/background"
@onready var magenta: Sprite2D = $"parallax_node/magenta"
@onready var camera: Camera2D = $"camera_2d"
@onready var buttons: Control = $"buttons"

var current_item: CanvasItem
var current_selection: int = 0
var _transitioning: bool = false


func _ready() -> void:
	if not SoundBoard.is_bgm_playing():
		SoundBoard.play_bgm(Globals.MENU_MUSIC, 0.7)
	update_selection()


func _unhandled_input(e: InputEvent) -> void:
	# prevents a bug with moving the mouse which would change selections nonstop
	if e is InputEventMouseMotion:
		return

	if _transitioning == true:
		return

	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	if ud: update_selection(ud)
	if Input.is_action_just_pressed("ui_accept"):
		confirm_selection()


func update_selection(new_sel: int = 0) -> void:
	if is_instance_valid(current_item) and current_item is AnimatedSprite2D:
		current_item.play("idle")
	current_selection = wrapi(current_selection + new_sel, 0, buttons.get_child_count())
	if new_sel != 0: SoundBoard.play_sfx(Globals.MENU_SCROLL_SFX)
	current_item = buttons.get_child(current_selection)
	if current_item is AnimatedSprite2D:
		current_item.play("selected")
	camera.position.y = current_item.position.y * current_item.scale.y


func confirm_selection():
	bye_bye_buttons()
	_transitioning = true
	SoundBoard.play_sfx(Globals.MENU_CONFIRM_SFX)
	if Preferences.flashing:
		Globals.begin_flicker(magenta, 1.1, 0.15, false)
		Globals.begin_flicker(current_item, 1.0, 0.06, false)
	await get_tree().create_timer(1.0).timeout
	match current_item.name:
		"story":
			Globals.change_scene(load("res://scenes/menu/story_menu.tscn"))
		"freeplay":
			Globals.change_scene(load("res://scenes/menu/freeplay_menu.tscn"))
		"options":
			var ow: Control = Globals.get_options_window()
			PerformanceCounter.add_child(ow)
			current_item.self_modulate.a = 1.0
			get_tree().paused = true
			_transitioning = false
			bye_bye_buttons(true)
		"merch":
			OS.shell_open("https://needlejuicerecords.com/pages/friday-night-funkin")
			current_item.self_modulate.a = 1.0
			_transitioning = false
			bye_bye_buttons(true)
		_:
			push_warning("button pressed was ", current_item.name, " but there is no action defined for it")
			current_item.self_modulate.a = 1.0
			_transitioning = false
			bye_bye_buttons(true)


func bye_bye_buttons(coming_back: bool = false) -> void:
	var val: float = 1.0 if coming_back else 0.0
	var duration: float = 0.5 if coming_back else 0.8
	for button: CanvasItem in buttons.get_children():
		if button != current_item:
			create_tween().set_ease(Tween.EASE_OUT) \
			.tween_property(button, "modulate:a", val, duration)
