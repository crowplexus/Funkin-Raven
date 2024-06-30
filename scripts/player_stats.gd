extends Node
class_name PlayerStats

## Score, 0 by default.
@export var score:  int = 0
#	get:
#		# convert accuracy to score
#		# increase by note hits
#		# decrease by misses.
#		return 0
## Combo Breaks, 0 by default
@export var breaks: int = 0
## Note Misses, 0 by default.
@export var misses: int = 0
## Note Combo, 0 by default.
@export var combo : int = 0

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


func _to_string() -> String:
	var status: String = "Score: %s - Accuracy: %s%% - Combo Breaks: %s" % [
		score, snappedf(accuracy, 0.01), breaks,
	]
	# crazy frog.
	if breaks < 10:
		var cf: String = Scoring.get_clear_flag(hit_registry)
		if breaks > 0: cf = "SDCB"
		if not cf.is_empty(): status += " (%s)" % cf
	return status


func _init() -> void:
	for judge: String in Scoring.JUDGMENTS.keys():
		hit_registry[judge] = 0


func save() -> void:
	var _date: = Time.get_datetime_string_from_system(true, true)
