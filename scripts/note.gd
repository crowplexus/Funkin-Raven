extends Resource
## Raw Note Data, used to spawn the notes,
## it is also used to a lesser extent in inputs.
class_name Note
## Hit Result event, created when hitting notes
class HitResult extends RefCounted:
	var player: Player
	var judgment: Dictionary
	var hit_time: float
	var data: Note

var object: CanvasItem

#region Spawn Data

## Spawn Time of the Note
@export var time: float = 0.0
## Column where the note spawns,
## for example, 2 would be Down / Light Blue
@export var column: int = 0
## Player who owns this note, declareed when loading charts.
@export var player: int = 0
## The note's kind, often declaring how it behaves
@export var kind: StringName = "normal"
## The note's hold length, gives any Tap Notes
## a tail of a specific size.
@export var hold_length: float = 0.0

#endregion

#region Input Data

## Hit Flag, declares what landed a hit on a tap note.[br][br]
## -1 - Missed.[br]
## 0 - Nothing / No one[br]
## 1 - a Player.[br]
## 2 - a Bot, AI or CPU.
@export_enum("Miss:-1", "None:0", "Player:1", "AI:2")
var hit_flag: int = 0
## The note's initial position, used for offsetting.
var initial_pos: Vector2 = Vector2.ZERO
## If the note behaves like a player note.
var as_player: bool = false
## How fast the note's object scrolls through the screen
var speed: float = 1.0

#endregion

#region Other Utility Functions

## Sorts Data by using two Note objects, use with arrays.
static func sort_by_time(first: Note, next: Note) -> int:
	return first.time < next.time

#endregion
