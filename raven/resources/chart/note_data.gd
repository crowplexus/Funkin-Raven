class_name NoteData extends Resource
# NOTE: notes are not dependant on these.
enum Type { NORMAL, MINE }
enum Direction { LEFT, DOWN, UP, RIGHT }
enum NColors { PURPLE, BLUE, GREEN, RED }
enum Lane { ENEMY, PLAYER, OTHER }

@export var time: float = 0.0
@export var s_len: float = 0.0
@export var dir: int = Direction.LEFT
@export var lane: int = Lane.ENEMY
@export var type: int = Type.NORMAL

func _to_string():
	return "Time:%s//Direction:%s//Type:%s//Lane:%s//Sustain Length:%s" % [
		time, Direction.keys()[dir], Type.keys()[type], Lane.keys()[lane],
		s_len
	]

static func dir_to_str(d: int): return NoteData.Direction.keys()[d].to_lower()
static func color_to_str(d: int): return NoteData.NColors.keys()[d].to_lower()

static func type_from_string(typename: StringName):
	var number: int = NoteData.Type.keys().find(typename.to_upper())
	return number if number != -1 else 0
