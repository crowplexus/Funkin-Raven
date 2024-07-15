extends Resource
## Raw Note Data, used to spawn the notes,
## it is also used to a lesser extent in inputs.
class_name Note
## Hit Result event, created when hitting notes
class HitResult extends RefCounted:
	var player: Player
	var judgment: Dictionary = Scoring.JUDGMENTS.miss.duplicate()
	var hit_time: float = 0.0

	static func make(p: Player, ht: float, j: Dictionary) -> Note.HitResult:
		var hit_result: = Note.HitResult.new()
		hit_result.judgment.merge(j, true)
		hit_result.hit_time = ht
		hit_result.player = p
		return hit_result


var object: CanvasItem
var notefield: NoteField
var receptor: CanvasItem:
	get:
		if is_instance_valid(notefield):
			return notefield.get_receptor(column)
		return null

#region Spawn Data

## Spawn Time of the Note
@export var time: float = 0.0
## Column where the note spawns,
## for example, 2 would be Down / Blue
@export var column: int = 0
## Player who owns this note, declared when loading charts.
@export var player: int = 0
## The note's kind, often declaring how it behaves
@export var kind: StringName = "normal"
## The note's hold length, gives any tap notes
## a tail with a specific size based on how many seconds long it should be.
@export var hold_length: float = 0.0
## Note scroll direction[br]
## Defaults to Vector2(1, 1)
@export var scroll: Vector2 = Vector2(1, 1)

#endregion
#region Input Data

## Tells if the note was hit earlier or later[br]
## 1 being early, 2 being late.
@export_enum("Undefined:0", "Early:1", "Late:2")
var hit_timing: int = 0
## Hit Information.
var hit_result: HitResult

## If the note's hold was dropped from input.
var dropped: bool = false
## Hold Note trip timer, used for inputs to knowing when to drop the hold.
var trip_timer: float = 0.0

#endregion
#region SV Data

## The note's initial position, used for offsetting.
@export var initial_pos: Vector2 = Vector2.ZERO
## Note's [bold]visual[/bold] time, used when positioning.
@export var visual_time: float = 0.0
@export var hold_progress: float = 0.0
## How fast the note's object scrolls through the screen.
@export var speed: float = 1.0

var real_speed: float:
	get:
		var scroll_speed: float = speed
		match Preferences.scroll_speed_behaviour:
			1: scroll_speed += Preferences.scroll_speed
			2: scroll_speed  = Preferences.scroll_speed
		scroll_speed /= AudioServer.playback_speed_scale
		return scroll_speed

#endregion
#region Updating
## Debug Mode forces certain behaviour functions for notes to disable
var debug_mode: bool = false
## If the note is moving towards its receptor.
var moving: bool = true
## If the note finished operating (was hit or missed, etc)
var finished: bool = false
var _late_hold: bool = false
var note_flew: Callable = func(_note: Note) -> void: pass

#endregion
#region Other Utility Functions

func move() -> void:
	if not object or not moving:
		return

	var rel_time: float = visual_time - Conductor.time
	var real_position: Vector2 = Vector2.ZERO
	var note_scale: float = 0.7
	if receptor:
		real_position = receptor.global_position
	object.global_position = initial_pos + real_position
	object.position.x *= scroll.x
	#object.position.x = initial_position.x + (90 * object.scale.x) * column
	object.position.y += rel_time * (400.0 * absf(real_speed)) / absf(note_scale) * scroll.y
	#object.position *= scroll
	if (time - Conductor.time) < (-.2 - hold_length):
		if note_flew and not note_flew.is_null():
			note_flew.call(self)
		moving = false
		finished = true
		if object: object.queue_free()

func reset(in_debug: bool = false) -> void:
	moving = true
	dropped = false
	finished = false
	debug_mode = in_debug
	hold_progress = hold_length
	_late_hold = false
	#if hit_result:
	#	hit_result.unreference()
	visual_time = time
	trip_timer = 0.0
	hit_timing = 0

func reset_scroll(_scroll: Vector2 = Vector2.ONE) -> void:
	scroll = _scroll
	if is_instance_valid(object) and object.has_method("reset_scroll"):
		object.call_deferred("reset_scroll", scroll)

## Sorts Data by using two Note objects, use with arrays.
static func sort_by_time(first: Note, next: Note) -> int:
	return first.time < next.time

static func get_quant(beat: float) -> int:
	var quants: Array[int] = [4,8,12,16,20,24,32,48,64,96,192]
	var row: int = Conductor.beat_to_row(beat)
	for qua: int in quants:
		if row % (Conductor.rows_per_bar / qua) == 0:
			return quants.find(qua)
	return 0

static func get_colour(secs: float, note_column: int = 0) -> Color:
	match Preferences.note_colouring_mode:
		1:
			var beat_time: float = Conductor.time_to_beat(secs)
			return Preferences.note_colours[1][Note.get_quant(beat_time)]
		_:
			return Preferences.note_colours[0][note_column]

static func make_dummy_hold() -> TextureRect:
	var hold: TextureRect = TextureRect.new()
	hold.stretch_mode = TextureRect.STRETCH_TILE
	#hold.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	return hold

#endregion
