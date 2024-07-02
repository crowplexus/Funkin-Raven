extends Control
class_name DialogueBox

signal conversation_finished()
signal line_advanced(next_line: int, line_count: int, was_immediate: bool)
signal line_skipped(line_id: int, line_count: int)

@export var writer: RichTextLabel
@onready var blip_player: AudioStreamPlayer = $"blip_player"
@onready var animation: AnimationPlayer = $"animation_player"
## Lines of dialogue to be written.
var lines: Array[DialogueLine] = []
## Current displayed line.
var current_line: DialogueLine:
	get: return lines[current_line_id]
var current_line_id: int = 0

var _line_progress: Tween
var _prev_line_count: int = 0
var _line_finished: bool = false
var _scroll_pointer: int = 0
var _is_ready: bool = false


func _ready() -> void:
	finish_line()
	#advance line, this is to display the first line of dialogue
	#advance(0, true)
	await get_tree().create_timer(0.01).timeout
	if animation.has_animation("open"):
		animation.play("open")
		animation.animation_finished.connect(func(s: StringName):
			match s:
				"open":
					_is_ready = true
					advance()
		)
	else:
		_is_ready = true
		advance()


func _process(_delta: float) -> void:
	if current_line and not _line_finished and _prev_line_count < writer.visible_characters:
		# dont play the blip if the next line is empty
		var true_text: String = current_line.text[_prev_line_count].dedent().replace("\\n", "\n")
		if not true_text.is_empty() and not true_text == "\n":
			play_dialogue_sound()
		_prev_line_count = writer.visible_characters
	if _prev_line_count >= current_line.get_pure_text().length():
		_line_finished = true


func _unhandled_key_input(event):
	if event and event.pressed and _is_ready:
		if event.is_action("ui_accept"):
			if _line_finished: advance(1)
			else: skip()
		if event.is_action("ui_cancel") and not _line_finished:
			skip()
		var lr_diff: int = int(Input.get_axis("ui_up", "ui_down"))
		if lr_diff and _line_finished:
			# i was gonna make a very complicated scroll thingy but apparently this exists
			# thank you godot.
			update_scroll_pointer(lr_diff)
			writer.scroll_to_line(_scroll_pointer)


func skip() -> void:
	if current_line and writer.visible_characters < current_line.text.length():
		if is_instance_valid(_line_progress):
			_line_progress.stop()
		finish_line()
		snap_pointer_to_end()
		writer.scroll_to_line(_scroll_pointer)
		line_skipped.emit(current_line_id, lines.size())


func advance(new: int = 0, immediate: bool = false) -> void:
	var next: int = current_line_id + new
	if lines.size() < (next+1):
		finish_conversation()
		return

	current_line_id = clampi(next, 0, lines.size())
	line_advanced.emit(current_line_id, lines.size(), immediate)
	_line_finished = false
	if immediate == true:
		writer.text = current_line.text
		finish_line()
		return

	_prev_line_count = 0
	writer.visible_characters = 0
	writer.text = current_line.text
	if is_instance_valid(_line_progress):
		_line_progress.stop()
	_line_progress = create_tween()
	var line_len: int = current_line.get_pure_text().length()
	var duration: float = line_len / current_line.speed
	_line_progress.tween_property(writer, "visible_characters", line_len, duration)
	snap_pointer_to_end()

## Snaps the position of the scroll pointer to the end of the text field.
func snap_pointer_to_end() -> void:
	_scroll_pointer = writer.get_line_count()
	update_scroll_pointer()

## Forces the line to be finished regardless of whether it's still being written or not
func finish_line() -> void:
	var line_len: int = current_line.get_pure_text().length()
	writer.visible_characters = line_len
	_prev_line_count = line_len
	_line_finished = true
	snap_pointer_to_end()


## Forces the dialogue sequence to end.
func finish_conversation() -> void:
	# can't do this because the last line of text will be lost.
	#current_line.text = ""
	finish_line()
	if animation.has_animation("close"):
		animation.play("close")
		await animation.animation_finished
		conversation_finished.emit()
		queue_free()
	else:
		conversation_finished.emit()
		queue_free()


func update_scroll_pointer(new: int = 0) -> void:
	var lbs: int = writer.get_line_count() - 4
	if writer.is_ready(): _scroll_pointer = clampi(_scroll_pointer + new, 0, lbs)


func play_dialogue_sound() -> void:
	if not current_line.blips.is_empty():
		blip_player.stream = current_line.blips.pick_random()
		blip_player.play(0.0)
