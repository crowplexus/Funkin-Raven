class_name Character extends AnimatedSprite2D
enum AnimContext { DANCE, SING, SPECIAL }

const DEFAULT_CHARACTER: String = "face"
@onready var animplayer: AnimationPlayer = $anim

#region Character Variables

@export_category("UI")

@export var health_icon: Texture2D = preload("res://assets/images/chars/icons/face.png")
@export var camera_offset:Vector2 = Vector2.ZERO

@export_category("Gameplay")

@export var singing_steps: Array[String] = ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
@export var dancing_steps: Array[String] = ["idle"]

@export var dance_interval: int = 2
@export var sing_duration: float = 5.0

@export_category("Game Over (set on \"dead_self\")")

@export var dead_self: PackedScene = preload("res://raven/game/actors/bf-dead.tscn")
@export var sound_on_death: AudioStream = load("res://assets/audio/sfx/game/deathNoise.ogg")
@export var sound_on_retry: AudioStream = load("res://assets/audio/sfx/game/deathEnd.ogg")
@export var music_on_death: AudioStream = load("res://assets/audio/bgm/gameOver.ogg")

@export_category("Metadata")

@export var is_player: bool = false
@export var dance_anim_suffix: String = ""
@export var sing_anim_suffix: String = ""

#endregion

#region Character Behavior

var actor_name: String = "bf"

var lock_sing: bool = false
var animation_context: = AnimContext.DANCE
var idle_cooldown: float = 0.0

var _last_queued_anim: StringName
var _is_real_player: bool = false
var _has_control: bool = false
var _dance_step: int = 0

#endregion

func _ready():
	if is_player and not _is_real_player:
		scale.x *= -1
	dance(true)

func _process(delta: float):
	if animation_context != AnimContext.DANCE and not lock_sing:
		if idle_cooldown > 0.0:
			idle_cooldown -= delta * (sing_duration * (Conductor.step_mult * 0.25))
		if idle_cooldown <= 0.0:
			var _dance_codition: bool = (
				_has_control and not Input.is_anything_pressed()
				or animation_context == AnimContext.SPECIAL
			)
			if _dance_codition or not _has_control:
				dance()

#region Functions

func stop_current_anim():
	if animplayer == null: return
	animplayer.stop()
	animplayer.seek(0.0)
	frame = 0

func play_anim(anim_name: StringName, force: bool = false, reverse: bool = false, next_frame: int = 0, speed: float = 1.0):
	if animplayer == null or not has_anim(anim_name):
		if not has_anim(anim_name):
			push_warning('"%s" has no animation named "%s"' % [name, anim_name] )
		return
		
	if force or _last_queued_anim != anim_name:
		frame = next_frame
		animplayer.seek(floorf(next_frame))
	
	animplayer.play(anim_name, -1, speed, reverse)
	_last_queued_anim = anim_name

func has_anim(anim_name: StringName):
	if animplayer == null: return false
	return animplayer.has_animation(anim_name)

func dance(force: bool = false):
	play_anim(dancing_steps[_dance_step] + dance_anim_suffix, force)
	if dancing_steps.size() > 1:
		_dance_step = wrapi(_dance_step + 1, 0, dancing_steps.size())
	animation_context = AnimContext.DANCE

func sing(dir: int, force: bool = false):
	play_anim(singing_steps[dir] + sing_anim_suffix, force)
	animation_context = AnimContext.SING

func miss(dir: int, force: bool = false):
	if not animplayer.has_animation(singing_steps[dir] + "miss"): return
	play_anim(singing_steps[dir] + "miss", force)
	idle_cooldown = (10 * Conductor.stepc)

func try_dying():
	if dead_self == null: return false
	
	var scene: = get_tree().current_scene
	
	# place your graveyard ( game over screen )
	var graveyard: Node2D = load("res://raven/game/game_over.tscn").instantiate()
	graveyard.z_index = 10
	
	# Place your skeleton (dead character scene)
	var my_skeleton: Character = dead_self.instantiate() as Character
	my_skeleton.global_position = self.global_position
	if _is_real_player:
		my_skeleton.scale.x *= -1
	graveyard.add_child(my_skeleton)
	self.visible = false
	
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	scene.add_child(graveyard)
	
	return true
#endregion
