extends Resource
class_name ChartEvent
## Event Name, for the Chart Editor and identification in scripts.
@export var name: StringName = &"None"
## Event Trigger Time, in steps.
@export var step: float = 0.0
## Event Type (for the chart editor)
@export_enum("Value Box:0", "Dropdown:1")
var type: int = 0
@export var values: Dictionary = {}
## Custom Function to run for the event
@export var custom_func: Callable
## Delay (in steps) for firing the event.
@export var delay: float = 0.0
## Internal, dictates if the event was fired.
var fired: bool = false


func _to_string() -> String:
	return "Name %s | Step: %s | Values: %s" % [ name, step, values ]
