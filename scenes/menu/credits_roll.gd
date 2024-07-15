extends Node2D

signal finished()

@onready var timer: Timer = $"timer"
@onready var animation: AnimationPlayer = $"animation_player"
@onready var colour_rect: ColorRect = $"colour_rect"
@onready var skip_label: Label = $"skip_text"

## Order of the animations, if this is empty,
## we will fill this with the animation player's list
@export var ordering: PackedStringArray = []
# gonna be controlling everything with the animation player,
# so yeah i need this
var current: int = 0


func _ready() -> void:
	SoundBoard.play_bgm(Globals.CREDITS_MUSIC)
	var key: String = InputMap.action_get_events("ui_accept")[0].as_text().to_upper()
	skip_label.text = skip_label.text.replace("{UI_ACCEPT}", key)
	colour_rect.modulate.a = 0.0
	var f: Tween = create_tween().set_ease(Tween.EASE_IN).bind_node($"colour_rect")
	f.tween_property(colour_rect, "modulate:a", 0.6, 0.5)
	await f.finished

	if ordering.is_empty():
		ordering = animation.get_animation_list()

	change_to_next(0) # play first animation
	# sync to Conductor later maybe uhhhhhhhhhhhh
	timer.start(animation.current_animation_length)
	timer.timeout.connect(change_to_next)


func _unhandled_input(_e: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		end()

func change_to_next(new: int = 1) -> void:
	if (current + new) >= ordering.size():
		end()
		return

	current = wrapi(current + new, 0, ordering.size())
	animation.play( ordering[current] )


func end() -> void:
	SoundBoard.fade_bgm(SoundBoard.get_bgm_volume(), 0.001, 1.5)
	var e: Tween = create_tween().set_ease(Tween.EASE_OUT).bind_node(self)
	e.tween_property(self, "modulate:a", 0.0, 1.25)
	await e.finished
	SoundBoard.cancel_bgm_fade_tween()
	SoundBoard.play_bgm(Globals.MENU_MUSIC, 0.7)
	finished.emit()
	queue_free()
