extends Control

@onready var panel: Panel = $panel
@onready var cata_alpha: Alphabet = $label/alphabet
@onready var categories: Array = $panel/container.get_children()
## Contains only the option bars in the category.
@onready var category_options: Array:
	get: return categories[category].get_children() \
		.filter(func(a: Node) -> bool: return a is OptionsBar)
## Contains every node in the category, including options.
@onready var category_nodes: Array:
	get: return categories[category].get_children()

@onready var selecty_boy: ColorRect = $panel/selecty_boy
@onready var desc_label: Label = $panel2/label
@onready var tip_label: Label = $tip

var idelta: int = 0
var selected: int = 0
var true_selected: int:
	get: return category_nodes.find(selected_option_var)
var category: int = 0

var is_anything_selected: bool = false
var selected_option_var: OptionsBar:
	get: return category_options[selected]

var selected_cata_var: VBoxContainer:
	get: return categories[category]

var show_up_twn: Tween
var selection_thing: Tween
var close_callback: Callable
var intended_pos: float = 0.0

var _parent_og_visibility: float = 1.0
func _ready() -> void:
	if $"../" != null and $"../" is CanvasItem:
		self.top_level = true
		_parent_og_visibility = $"../".modulate.a
		$"../".modulate.a = 0.5
	update_category()

func _unhandled_key_input(e: InputEvent) -> void:
	if not e.pressed: return

	if not is_anything_selected:
		match e.keycode:
			KEY_ESCAPE:
				Settings.save_settings()
				close_callback.call_deferred()
				await RenderingServer.frame_post_draw
				if $"../" != null:
					if $"../" is CanvasItem:
						$"../".modulate.a = _parent_og_visibility
					$"../".process_mode = Node.PROCESS_MODE_ALWAYS
				queue_free()

		var axis_ud: int = int( Input.get_axis("ui_up", "ui_down") )
		var axis_lr: int = int( Input.get_axis("ui_left", "ui_right") )
		if axis_ud: update_selected(axis_ud)
		if axis_lr: update_category(axis_lr)

	if selected_option_var != null:
		if Input.is_action_pressed('ui_accept'):
			selected_option_var.selected = not selected_option_var.selected

		if selected_option_var.selected and Input.is_action_pressed('ui_cancel'):
			selected_option_var.selected = false

		is_anything_selected = selected_option_var.selected

func _process(delta: float) -> void:
	if selected_option_var != null:
		selecty_boy.global_position.x = selected_option_var.global_position.x
		if selecty_boy.global_position.y != selected_option_var.global_position.y:
			selecty_boy.global_position.y = Tools.exp_lerp(
				selecty_boy.global_position.y,
				selected_option_var.global_position.y, 20)

		if selected_cata_var.position.y != intended_pos:
			selected_cata_var.position.y = Tools.exp_lerp(
				selected_cata_var.position.y,
				intended_pos, 20)
		selecty_boy.color = Color("6aff00" if is_anything_selected else "ffe200")

	idelta += int(delta)
	selecty_boy.color.a = sin(idelta * 4) / 8 + 0.4

func update_selected(amnt: int = 0) -> void:
	selected = wrapi(selected + amnt, 0, category_options.size())
	if amnt != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	update_display(amnt)
	update_desc()

func update_category(amnt: int = 0) -> void:
	if show_up_twn != null: show_up_twn.stop()
	show_up_twn = create_tween().set_ease(Tween.EASE_IN)

	category = wrapi(category + amnt, 0, categories.size())
	if amnt != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)

	for le_cata: VBoxContainer in categories:
		for item in le_cata.get_children():
			if item is Label: item.text = tr(item.name)
			elif item is OptionsBar:
				item.reload_name()
				item.reload_value_name()

	for next_category: VBoxContainer in categories:
		next_category.visible = next_category == selected_cata_var # just in case
		next_category.modulate.a = 0.0
	show_up_twn.tween_property(selected_cata_var, "modulate:a", 1.0, 0.3)

	cata_alpha.text = tr(selected_cata_var.name)
	tip_label.text = tr("options_tip")
	update_selected()

func update_display(_amnt: int = 0) -> void:
	intended_pos = 0.0
	if selected_cata_var == null or selected == 0 or selected_cata_var.size.y <= panel.size.y:
		return
	intended_pos = (panel.size.y - selected_cata_var.size.y) * ((selected_option_var.position.y + selected_option_var.size.y) / selected_cata_var.size.y)

func update_desc(add_this: String = "") -> void:
	desc_label.text = ""
	if selected_option_var != null:
		var translated_desc: String = tr("desc_" + selected_option_var.name)
		if translated_desc.begins_with("desc_"):
			desc_label.text = selected_option_var.description
		else:
			desc_label.text = translated_desc
		if not add_this.is_empty():
			desc_label.text += add_this

		if selected_option_var.restart_on_gameplay:
			var restart_txt: String = tr("desc_will_restart")
			if restart_txt.begins_with("desc_"):
				restart_txt = "Will restart if you're already playing"
			desc_label.text += "\n" + restart_txt
