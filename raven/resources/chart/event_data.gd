class_name EventData extends Resource
enum Type { ONESHOT, PERIODICALLY }

@export var name: StringName = "none"
@export var args: Array = []
@export var time: float = 0.0
@export var end_time: float = -1.0
@export var type: = Type.ONESHOT

func _to_string():
	var event_str: String = "Name: %s | Arguments: %s | Type: %s" % [name, args, type]
	if time > -1.0: event_str += " | Time: %s" % time
	if end_time > -1.0: event_str += " / %s" % end_time
	return "{%s}" % event_str
