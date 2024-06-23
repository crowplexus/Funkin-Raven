extends Control

@onready var page_list: Panel = $"pages"
@onready var help_text: Label = $"help_text"
@onready var page_selector: = $"left_panel/page_selector"
@onready var active_page: VBoxContainer = $"pages/gameplay"
@onready var option_descriptor: Label = $"descriptor"
@onready var selector: = $"pages/selector"
@onready var all_pages: Array:
	get:
		if not is_instance_valid(page_list):
			return []
		return page_list.get_children().filter(func(node):
			return node is VBoxContainer
		)
## [READ-ONLY] gives you the maximum amount of items in the current page.
@onready var page_size: int:
	get:
		if is_instance_valid(active_page):
			return active_page.get_child_count()
		return 0

## Current selected preference box.
var selected_pref: OptionItem
## Current selected item.
var current_selection: int = 0
## Disables scrolling if you are changing a preference.
var changing_preference: bool = false

var _display_ypos: float = 0.0
var _just_started: bool = true # bandaid


func _ready() -> void:
	var _v: float = 0.0
	for page: VBoxContainer in all_pages:
		var a: Control
		if page.get_index() == 0:
			a = page_selector.get_child(0)
		else:
			a = page_selector.get_child(0).duplicate()
			page_selector.add_child(a)
		a.name = page.name
		a.option_name = page.name.to_upper()
		_v += a.size.y

	update_page()
	# i hate this <3
	await RenderingServer.frame_post_draw
	_just_started = false


func _process(delta: float) -> void:
	if is_instance_valid(selected_pref):
		if selector.position.y != selected_pref.position.y:
			selector.position.y = lerpf(selected_pref.position.y + _display_ypos,
				selector.position.y, exp(-delta * 32))

	if is_instance_valid(active_page):
		if active_page.position.y != _display_ypos:
			active_page.position.y = lerpf(active_page.position.y, _display_ypos, exp(-delta * 64))


func _unhandled_input(e: InputEvent) -> void:
	if _just_started:
		return

	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	var lr: int = int(Input.get_axis("ui_left", "ui_right"))
	if e is InputEventMouse and e.shift_pressed:
		lr = ud

	if changing_preference:
		var shift_mult: int = 1
		if Input.is_key_label_pressed(KEY_SHIFT):
			shift_mult = 5
		if lr: selected_pref.update(shift_mult * lr)
	else:
		if ud: update_selection(ud)
		if lr: update_page(lr)

	if e is InputEventKey and e.pressed and e.keycode == KEY_F1:
		help_text.visible = not help_text.visible

	if not e is InputEventMouse and Input.is_action_just_pressed("ui_accept"):
		changing_preference = not changing_preference
		selector.modulate = Color.GREEN if changing_preference else Color.WHITE

	if not e is InputEventMouse and Input.is_action_just_pressed("ui_cancel"):
		if changing_preference:
			stop_changing_pref()
		else:
			Preferences.save_prefs()
			create_tween().set_ease(Tween.EASE_OUT).bind_node(self) \
			.tween_property(self, "modulate:a", 0.0, 0.2) \
			.finished.connect(self.leave)


func stop_changing_pref() -> void:
	selector.modulate = Color.WHITE
	changing_preference = false
	match selected_pref.name:
		"language": reload_text()
		_ when selected_pref.name.ends_with("keybind"):
			Preferences.init_keybinds()


func update_selection(new: int = 0) -> void:
	if is_instance_valid(selected_pref):
		selected_pref.modulate.a = 0.6
	current_selection = wrapi(current_selection + new, 0, page_size)
	selected_pref = active_page.get_child(current_selection)
	if new != 0: SoundBoard.play_sfx(Globals.MENU_SCROLL_SFX)
	selected_pref.modulate.a = 1.0
	reload_description()

	_display_ypos = 0.0
	# original scrolling code by @srthero278 / @srtpro278.
	if page_size > 8 and active_page.size.y >= page_list.size.y:
		_display_ypos = (
			((page_list.size.y - active_page.size.y) - page_size + 33)
			* ((selected_pref.position.y - selected_pref.size.y + selected_pref.size.y)
			/ page_list.size.y)
		)


func update_page(new_page: int = 0, page_override: int = -1) -> void:
	var current_page: int = all_pages.find(active_page)
	if page_override > -1: current_page = page_override
	if is_instance_valid(active_page):
		active_page.hide()

	current_page = wrapi(current_page + new_page, 0, all_pages.size())
	if new_page != 0 or page_override > -1:
		SoundBoard.play_sfx(Globals.MENU_SCROLL_SFX)
	# i give tf up i'm just gonna do this.
	for a: Control in page_selector.get_children():
		a.modulate.a = 1.0 if a.get_index() == current_page else 0.6
	active_page = all_pages[current_page]
	active_page.show()
	update_selection()


func reload_text() -> void:
	reload_description()
	for page: VBoxContainer in all_pages:
		for pref: OptionItem in active_page.get_children():
			pref.reset_preference_label()


func reload_description() -> void:
	if not is_instance_valid(selected_pref):
		return
	var description: String = "(No description provided.)"
	if not selected_pref.description.is_empty():
		description = selected_pref.description
	option_descriptor.text = description


func _calculate_page_size() -> Vector2:
	var v: Vector2 = Vector2.ZERO
	for page: OptionItem in active_page.get_children():
		v += page.size
	return v


func leave() -> void:
	if get_tree().paused:
		get_tree().paused = false
	await RenderingServer.frame_pre_draw
	self.queue_free()
