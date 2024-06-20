extends Resource
class_name ChartEvent
## Event Name, for the Chart Editor and identification in scripts.
@export var name: StringName = &"None"
## Event Trigger Time, in Steps.
@export var time: float = 0.0
## Event Type (for the chart editor)
@export_enum("Value Box:0", "Dropdown:1")
var type: int = 0
@export var values: Array = []
## Custom Function to run for the event
@export var custom_func: Callable


func _to_string() -> String:
	return "ShartEvent(Name %s - Step: %s - Values: %s)" % [ name, time, values ]
