@tool extends Control
class_name OptionItem

@onready var window: Control = $"../../../"
@onready var preference_label: Label = $"preference_label"

## The option's display name in the options window.
@export var option_name: StringName = "Unknown":
	set(new_name):
		option_name = new_name
		reset_preference_label()
@export var name_display: String = "@"
## The option's description in the options window.
@export_multiline var description: String = ""
## Preference variable name (in [code]Preferences[/code] class)
@export var variable: String = ""
## Type of the option, decides how it updates on the menu.[br]
## NOTE: Type 3 (Other) requires you to extend the base [code]PreferenceBar[/code] class.
@export_enum("Boolean:0", "Number:1", "List:2", "Other:3")
var option_type: int = 0
## Display names for values, only useful when the option type is List ([code]2[/code])
@export var display_names: Array[StringName] = []
## Number decimal points, only useful when the option type is Number ([code]1[/code])
@export var steps: float = 1.0
## Incremental speed used when holding shift while changing number options.
@export var speed: float = 8.0

## The preference's current value
var value: Variant


func _ready() -> void:
	check_value()


func update(amount: int = 0) -> void:
	match option_type:
		0: Preferences.set(variable, not value)
		1: Preferences.set(variable, value + steps * amount)
		2:
			var current_val: int = 0
			if value is int:
				current_val = value
			elif value is String or value is StringName:
				current_val = display_names.find(value)

			var next_value = wrapi(current_val + amount, 0, display_names.size())
			if value is String or value is StringName:
				next_value = display_names[next_value]
			Preferences.set(variable, next_value)
	#print_debug(value)
	check_value()


func check_value() -> void:
	value = Preferences.get(variable)
	reset_preference_label()


func reset_preference_label() -> void:
	if preference_label:
		var final_text: String = option_name
		# display value name in there too #
		if option_type < 3:
			final_text += ": %s" % get_value_name()
		preference_label.text = final_text


func get_value_name() -> StringName:
	var value_name: StringName = str(value)
	match value_name.to_snake_case():
		"true": value_name = "ON"
		"false": value_name = "OFF"
		"<null>": value_name = "?"
		_:
			match option_type:
				2:
					if value is int:
						value_name = display_names[value]
					elif value is String or value is StringName:
						value_name = display_names[display_names.find(value)]
	return name_display.replace("@", value_name)


func _on_mouse_entered() -> void:
	if not is_instance_valid(window):
		return
	if self != window.selected_pref:
		modulate.a = 0.8


func _on_mouse_exited() -> void:
	if not is_instance_valid(window):
		return
	if self != window.selected_pref:
		modulate.a = 0.6


func _on_gui_input(e: InputEvent) -> void:
	var can_input: bool = is_instance_valid(window)
	if not can_input:
		return

	if e.is_pressed() and e.is_action("ui_accept"):
		if self == window.selected_pref and  e.double_click == true:
			window.changing_preference = not window.changing_preference
			window.selector.modulate = Color.GREEN if window.changing_preference else Color.WHITE

		elif not window.changing_preference:
			window.current_selection = window.page_options.find(self)
			window.update_selection()
