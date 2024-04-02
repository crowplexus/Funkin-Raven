extends Control

@onready var cata_alpha: Alphabet = $label/alphabet
@onready var categories: Array = $panel/container.get_children()
@onready var category_items: Array:
	get: return categories[category].get_children()
@onready var selecty_boy: ColorRect = $panel/selecty_boy
@onready var desc_label: Label = $panel2/label

var idelta: int = 0
var selected: int = 0
var category: int = 0

var is_anything_selected: bool = false
var selected_option_var: OptionsBar:
	get:
		if category_items[selected] is OptionsBar:
			return category_items[selected]
		return null
var selected_cata_var: VBoxContainer:
	get: return categories[category]

var show_up_twn: Tween
var close_callback: Callable

func _ready():
	$bg.modulate.a = 0.0
	var bg_twn: Tween = create_tween()
	bg_twn.tween_property($bg, "modulate:a", 0.4, 0.5)
	#$tip.text = tr("options_tip")
	change_sel()
	change_cata()

func _unhandled_key_input(e: InputEvent):
	if not e.pressed: return
	
	if not is_anything_selected:
		match e.keycode:
			KEY_ESCAPE:
				Settings.save_settings()
				if close_callback != null: close_callback.call()
				await get_tree().create_timer(0.01).timeout
				$"../".process_mode = Node.PROCESS_MODE_ALWAYS
				queue_free()
			
		var axis_ud: int = int( Input.get_axis("ui_up", "ui_down") )
		var axis_lr: int = int( Input.get_axis("ui_left", "ui_right") )
		if axis_ud != 0: change_sel(axis_ud)
		if axis_lr != 0: change_cata(axis_lr)
	
	if selected_option_var != null:
		if Input.is_action_pressed('ui_accept'):
			selected_option_var.selected = not selected_option_var.selected
		
		if selected_option_var.selected and Input.is_action_pressed('ui_cancel'):
			selected_option_var.selected = false
		
		is_anything_selected = selected_option_var.selected

func _process(delta: float):
	if selected_option_var != null:
		selecty_boy.global_position.x = selected_option_var.global_position.x
		selecty_boy.global_position.y = Tools.lerp_fix(
			selecty_boy.global_position.y,
			selected_option_var.global_position.y,
			delta, 20)
		selecty_boy.color = Color("6aff00" if is_anything_selected else "ffe200")
	
	idelta += int(delta)
	selecty_boy.color.a = sin(idelta * 4) / 8 + 0.4

func change_sel(amnt: int = 0):
	selected = wrapi(selected + amnt, 0, category_items.size())
	var check: bool = not category_items[selected] is OptionsBar
	if check and category_items[selected + amnt] is OptionsBar:
		selected += amnt
	
	if amnt != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	update_desc()

func change_cata(amnt: int = 0):
	if show_up_twn != null: show_up_twn.stop()
	show_up_twn = create_tween().set_ease(Tween.EASE_IN)
	
	category = wrapi(category + amnt, 0, categories.size())
	if amnt != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	# i'm kind of frustrated and this works
	# will change it later tho @crowplexus
	selected = category_items.filter(func(a):
		return a is OptionsBar).front().get_index()
	
	for next_category: VBoxContainer in categories:
		next_category.visible = next_category == selected_cata_var # just in case
		next_category.modulate.a = 0.0
	show_up_twn.tween_property(selected_cata_var, "modulate:a", 1.0, 0.3)
	
	cata_alpha.text = tr(selected_cata_var.name)
	change_sel()

func update_display():
	#var current_index: int = selected_option_var.get_index()
	#for i: OptionsBar in category_items:
	#	pass
	pass

func update_desc():
	if selected_option_var != null:
		desc_label.text = selected_option_var.description
	else:
		desc_label.text = ""
