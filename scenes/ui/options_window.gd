extends Control

@onready var page_list: Panel = $"pages"
@onready var active_page: VBoxContainer = $"pages/gameplay"
@onready var page_name_label: Label = $"page_name_label"
@onready var option_descriptor: Label = $"descriptor"
@onready var selector: = $"pages/selector"
@onready var all_pages: Array:
	get:
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
var selected_pref: PreferenceBar
## Current selected item.
var current_selection: int = 0
## Disables scrolling if you are changing a preference.
var changing_preference: bool = false

var _display_ypos: float = 0.0


func _ready() -> void:
	update_page()


func _process(delta: float) -> void:
	if is_instance_valid(active_page):
		if selector.position.y != selected_pref.position.y:
			selector.position.y = lerpf(
				selector.position.y, selected_pref.position.y + _display_ypos,
				exp(-delta * 64))

		if active_page.position.y != _display_ypos:
			active_page.position.y = lerpf(active_page.position.y, _display_ypos, exp(-delta * 64))


func _unhandled_key_input(_event: InputEvent) -> void:
	var ud: int = int(Input.get_axis("ui_up", "ui_down"))
	var lr: int = int(Input.get_axis("ui_left", "ui_right"))
	if not changing_preference:
		if ud: update_selection(ud)
		if lr: update_page(lr)
	else:
		var shift_mult: int = 1
		if Input.is_key_label_pressed(KEY_SHIFT):
			shift_mult = 5
		if lr: selected_pref.update(shift_mult * lr)

	if Input.is_action_just_pressed("ui_accept"):
		changing_preference = not changing_preference
		selector.modulate = Color.GREEN if changing_preference else Color.WHITE

	if Input.is_action_just_pressed("ui_cancel"):
		if changing_preference:
			changing_preference = false
			selector.modulate = Color.WHITE
		else:
			create_tween().set_ease(Tween.EASE_OUT).bind_node(self) \
			.tween_property(self, "modulate:a", 0.0, 0.2) \
			.finished.connect(self.leave)


func update_selection(new: int = 0) -> void:
	current_selection = wrapi(current_selection + new, 0, page_size)
	selected_pref = active_page.get_child(current_selection)
	option_descriptor.text = selected_pref.description

	for pref: PreferenceBar in active_page.get_children():
		if pref == selected_pref: pref.modulate.a = 1.0
		else: pref.modulate.a = 0.6

	_display_ypos = 0.0
	# scrolling code by @srthero278 / @srtpro278
	if page_size > 8 and active_page.size.y >= page_list.size.y:
		_display_ypos = (
			(page_list.size.y - active_page.size.y + 210)
			* ((selected_pref.position.y - selected_pref.size.y + selected_pref.size.y)
			/ page_list.size.y)
		)


func update_page(new_page: int = 0) -> void:
	var current_page: int = all_pages.find(active_page)

	current_page = wrapi(current_page + new_page, 0, all_pages.size())
	active_page = all_pages[current_page]

	for page: VBoxContainer in all_pages:
		page.visible = page == active_page

	page_name_label.text = "< %s >" % active_page.name.to_pascal_case()
	update_selection()


func leave() -> void:
	if get_tree().paused == true:
		get_tree().paused = false
	self.queue_free()
