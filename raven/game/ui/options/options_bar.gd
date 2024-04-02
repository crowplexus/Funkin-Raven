@tool class_name OptionsBar extends Panel

static var will_restart_gameplay: bool = false
@onready var name_label: Label = $name_label
@onready var option_status: Label = $option_status

@export var setting: String = 'My Option' ## The name of the option shown in the menu.
@export var variable: String = 'scroll' ## The name of the var in [b]setting.gd[/b] you want to change.
@export_enum("Bool:0", "Int:1", "Float:2", "Array:3", "Custom:4")
var variable_type: int = 3 ## Self explanatory.

@export var value_format: String = "< @ >" ## "@" will be replaced by [code]val_name[/code].
@export_multiline var description = 'Very simple really...' ## The description that gets shown in the box below!!

@export var choice_names: Array[String] = [] ## Only useful if [code]variable_type[/code] is [b]Array[/b], the name of the choice shown in the menu.
@export var increment_rules: Array[float] = [] ## Incrementation rules for [b]Int[/b] or [b]Float[/b] values, [increment_amount, shift_multiplicator]
@export var restart_on_gameplay: bool = false

var val_name: StringName = "???" ## Current name displayed for the value.
var val: Variant ## Value of [code]variable[/code]
var selected: bool = false ## If selected, access to LEFT and RIGHT keys are given.

func _ready():
	if name_label != null: name_label.text = setting
	update_setting(0, true)

func _unhandled_key_input(_e: InputEvent):
	if selected:
		var axis_lr: int = int( Input.get_axis("ui_left", "ui_right") )
		if axis_lr != 0: update_setting(axis_lr)

func update_setting(amnt: int = 0, precache: bool = false):
	val = Settings.get(variable)
	if not precache:
		match variable_type: # set value
			0: val = not val # Bool
			1, 2: # Int, Float
				var shift_mult: float = 1.0 if not Input.is_key_pressed(KEY_SHIFT) else increment_rules[1]
				val = val + (increment_rules[0] * shift_mult) * amnt
			3: 
				if typeof(val) == TYPE_INT:
					val = wrapi(val + amnt, 0, choice_names.size()) # Array
				else:
					val = choice_names[wrapi(choice_names.find(val) + amnt, 0, choice_names.size())]
		if restart_on_gameplay: will_restart_gameplay = true
		Settings.set(variable, val)
		
		# reset value since it was set in the previous line.
		val = Settings.get(variable)
	
	match variable_type: # set name
		0: # Bool
			val_name = "ON" if val == true else "OFF"
			option_status.modulate = Color('00FF00') if val == true else Color('FF0000')
		1, 2: val_name = str( snappedf(val, 0.01) ) # Int, Float
		3: # Array
			if typeof(val) == TYPE_INT:
				val_name = str(choice_names[val % choice_names.size()])
			else: val_name = str(val)
	
	option_status.text = value_format.replace('@', val_name)
