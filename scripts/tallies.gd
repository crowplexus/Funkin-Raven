extends Resource
class_name Tally

## Score, 0 by default.
@export var score:  int = 0
## Combo Breaks, 0 by default
@export var breaks: int = 0
## Note Misses, 0 by default.
@export var misses: int = 0
## Note Combo, 0 by default.
@export var combo : int = 0
## Ghost Taps, 0 by default.
@export var ghost_taps: int = 0

	# accuracy values #
## Accuracy, used to measure how accurate are your note hits in a percentage form[br]
## 0.00% by default
@export var accuracy: float = 0.0:
	get:
		if total_notes_hit == 0: return 0.00
		return accuracy_threshold / (total_notes_hit + misses)

## Threshold of your note hits, measured in seconds[br]
## Used to calculate basic accuracy.
@export var accuracy_threshold: float = 0.0
## Total number of notes you've hit, doesn't reset when missing[br]
## Used to calculate basic accuracy.
@export var total_notes_hit: int = 0
## Contains judgments that you've hit.
@export var hit_registry: Dictionary = {}
## Date of when this stats resource was saved, changed whenever [code]register()[/code] is called.
@export var registry_date: String = "UNKOWN-DATE UNKNOWN-TIME"
## ID of the player who achieved the stats.
@export var player_id: int = 0
## Tells the game if the stats were saved with epics enabled.[br]
## for sorting reasons.
var had_epics: bool:
	get: return hit_registry.has("epic") and hit_registry.epic > 0
## Tells the game if the stats were obtained by cheating.
var invalid: bool:
	get: return hit_registry.has("perfect") and hit_registry.perfect > 0


func apply_hit(note: Note) -> void:
	if not note or not note.hit_result:
		return
	if not note.hit_result.judgment.name in hit_registry:
		hit_registry[note.hit_result.judgment.name] = 0
	hit_registry[note.hit_result.judgment.name] += 1
	score += Scoring.get_doido_score((note.time - Conductor.time) * 1000.0)
	if combo < 0:
		combo = 0
	total_notes_hit += 1
	accuracy_threshold += note.hit_result.judgment.accuracy
	combo += 1

func apply_miss(column: int = 0, note: Note = null) -> void:
	break_combo()
	if note:
		column = note.column
		misses += 1
	combo -= 1

func apply_ghost_tap(_column: int = 0) -> void:
	ghost_taps += 1

func break_combo() -> void:
	if combo > 1:
		combo = 0
		breaks += 1

func hit_registry_string() -> String:
	var counter: String = ""
	for i: int in hit_registry.keys().size():
		var key: String = hit_registry.keys()[i]
		if key == "perfect":
			continue
		if not counter.is_empty(): counter += "\n"
		counter += "%s: %s" % [key.to_pascal_case(), hit_registry[key]]
	if not counter.is_empty():
		counter += "\nMiss: %s" % [misses]
	return counter + "\n"

func _to_string() -> String:
	var status: String = "Score: %s\nAccuracy: %s%%\nCombo Breaks: %s" % [
			Globals.thousands_sep(score), snappedf(accuracy, 0.01), breaks]
	# crazy frog.
	if breaks < 10:
		var cf: String = Scoring.get_clear_flag(hit_registry)
		if breaks > 0: cf = "SDCB"
		if not cf.is_empty(): status += " (%s)" % cf
	return status

func _init() -> void:
	for judge: String in Scoring.JUDGMENTS.keys():
		if judge == "miss": continue
		hit_registry[judge] = 0

## Function use to register the date of when these tallies were obtained[br]
## Can be used with [code]ResourceSaver[/code] or [code]Highscore[/code]
## for registering purposes.
func register() -> Tally:
	registry_date = Time.get_datetime_string_from_system(false, true)
	#ResourceSaver.save(self, "res://"+song_name+".tres", ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES)
	return self
