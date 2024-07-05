extends Node2D
## ...
class_name Character

@onready var sprite: = $"sprite"
@onready var animation_player: AnimationPlayer = $"sprite/animation_player"

@export_category("Character")

## Quite self-explanatory.
@export var display_name: StringName = "Nameless"
## Current animation suffix, defaults to ""
@export var animation_suffix: String = ""
## Current animation context, defualts to Dancing ([code]0[/code])
@export_enum("Dancing:0", "Singing:1", "Special:2")
var animation_context: int = 0
## Duration of sing animations.
@export var sing_duration: float = 5.0
## Offset of the camera when focusing on the character.
@export var camera_offset: Vector2 = Vector2.ZERO
## Character's health icon, displayed on the healthbar.
@export var health_icon: HealthIcon
## If the character is (normally) a player character.
@export var is_player: bool = false

@export_category("Animations")

## List of idles, cycled through every [code]beat_interval[/code] beats
@export var idle_list: PackedStringArray = ["idle"]
## List of sing animations, used when hitting notes.
@export var sing_list: PackedStringArray = ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
## Interval (in beats) for characters to [code]dance()[/code]
@export var dance_interval: int = 2

var idle_cooldown: float = 0.0
var _current_idle: int = 0
var _previous_anim: StringName = ""
var _faces_left: bool = false


func _ready() -> void:
	if not is_instance_valid(animation_player):
		push_warning("Your character has no AnimationPlayer node attached to it, it will be unable to play animations.")
	else:
		Conductor.ibeat_reached.connect(try_dance)

	if is_player and not _faces_left:
		var left_idx: int = 0
		var right_idx: int = 0
		# swap left and right sprites
		# this is duuuuuuuuuuuuuuuumb
		for sing_anim: String in sing_list:
			if sing_anim.to_lower().ends_with("left") or sing_anim.to_lower() == "left":
				left_idx = sing_list.find(sing_anim)
			if sing_anim.to_lower().ends_with("right") or sing_anim.to_lower() == "right":
				right_idx = sing_list.find(sing_anim)

		var old_sl: = sing_list.duplicate()
		sing_list[left_idx] = old_sl[right_idx]
		sing_list[right_idx] = old_sl[left_idx]
		old_sl.clear()
		scale.x *= -1


func _process(delta: float) -> void:
	if animation_context != 0:
		if idle_cooldown > 0.0:
			idle_cooldown -= delta * (sing_duration * (Conductor.semibreve * 0.25))
		if idle_cooldown <= 0.0:
			dance()


func _exit_tree() -> void:
	if Conductor.ibeat_reached.is_connected(try_dance):
		Conductor.ibeat_reached.disconnect(try_dance)


func play_animation(anim: StringName, force: bool = false, force_frame: int = 0) -> void:
	if force or _previous_anim != anim:
		sprite.frame = force_frame
		if animation_player:
			animation_player.seek(0.0)
	if animation_player:
		animation_player.play(anim)
		#print_debug("i am ",display_name,"and i'm playing animation ",anim)
	_previous_anim = anim


func try_dance(beat: int) -> void: # i hate this <3 @crowplexus
	if idle_cooldown <= 0.0 and beat % dance_interval == 0:
		dance(sprite.frame_progress > 0.0)


func dance(force: bool = false, force_idle: int = -1) -> void:
	if force_idle > -1 and force_idle < idle_list.size():
		_current_idle = force_idle
	play_animation(idle_list[_current_idle], force)
	_current_idle = wrapi(_current_idle + 1, 0, idle_list.size())
	animation_context = 0


func sing(column: int, force: bool = false, suffix: String = "") -> void:
	var to_play: StringName = sing_list[column]
	if not suffix.is_empty() and animation_player.has_animation(to_play + suffix):
		to_play += suffix
	play_animation(to_play, force)
	animation_context = 1
