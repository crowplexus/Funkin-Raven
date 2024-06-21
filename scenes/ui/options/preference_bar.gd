@tool extends Control
class_name PreferenceBar

@onready var color_rect: ColorRect = $"color_rect"
@onready var preference_label: Label = $"preference_label"
## The option's display name in the options window.
@export var option_name: StringName = "Unknown":
	set(new_name):
		option_name = new_name
		reset_preference_label()
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

## The preference's current value
var value: Variant
var _force_name: StringName = ""


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
	if is_instance_valid(preference_label):
		var final_text: String = option_name
		# display value name in there too #
		if option_type < 3:
			final_text += ": %s" % get_value_name()
		preference_label.text = final_text


func get_value_name() -> StringName:
	if not _force_name.is_empty():
		var copy = _force_name
		_force_name = ""
		return copy

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

	return value_name
