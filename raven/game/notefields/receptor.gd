 ## Sprite representing a NoteField's Receptor
class_name Receptor extends AnimatedSprite2D

@onready var parent: NoteField = $"../../"
@onready var animplayer: AnimationPlayer = $anim

var reset_timer: float = 0.0
var reset_anim: String = "static"

var speed: float = -1.0:
	get:
		var pspeed: float = parent.speed if speed < 0.0 else speed
		if Settings.speed_mode != 0: match Settings.speed_mode:
			1: pspeed = Settings.scroll_speed
			2: pspeed += Settings.scroll_speed
		return pspeed 
var _last_anim: StringName = "press"

func _ready():
	if parent.debug: return
	reset_scroll()

func _process(delta: float):
	if reset_timer == 0.0: return
	reset_timer -= delta * (Conductor.step_mult * 0.25)
	if reset_timer <= 0.0:
		play_anim(reset_anim, true)

func reset_scroll(scroll: int = -1, tween: bool = false, tween_duration: float = 0.6):
	if scroll == -1: scroll = Settings.scroll
	var pos: int = 880
	
	match scroll:
		0: pos = 130 # Up
		1: pos = 880 # Down
		2: # Split (UD)
			var down: bool = get_index() >= 2
			pos = 880 if down else 130
		3: # Split (DU)
			var down: bool = get_index() <  2
			pos = 880 if down else 130
	
	if not tween: position.y = pos
	else:
		get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_CIRC) \
		.tween_property(self, "position:y", pos, tween_duration)

func play_anim(anim_name: StringName, force: bool = false):
	if animplayer == null: return
	if force or _last_anim != anim_name:
		frame = 0; animplayer.seek(0.0)
	animplayer.play(anim_name)
	_last_anim = anim_name

func queue_anim(anim_name: StringName, forced: bool = false, wait: float = 0.0):
	if animplayer == null: return
	animplayer.animation_finished.connect(func(_cur: StringName):
		if wait != 0.0: await get_tree().create_timer(wait).timeout
		play_anim(anim_name, forced), CONNECT_ONE_SHOT)
