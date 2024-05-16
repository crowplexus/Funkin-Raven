 ## Sprite representing a NoteField's Receptor
class_name Receptor extends AnimatedSprite2D
enum ActionType {
	STATIC	= 0,
	GHOST		= 1,
	GLOW		= 2,
}
@onready var parent: NoteField = $"../../"

var reset_timer: float = 0.0
var reset_callback: Callable = become_static
var skin: NoteSkin

var speed: float = -1.0:
	get:
		var pspeed: float = parent.speed if speed == -1.0 else speed
		if Settings.speed_mode != 0:
			match Settings.speed_mode:
				1: pspeed = Settings.scroll_speed
				2: pspeed += Settings.scroll_speed
		return pspeed

func _ready() -> void:
	var new_skin: NoteSkin = NoteSkin.create_if_exists()
	if new_skin != null:
		skin = new_skin
		skin.receptor = self
		skin.propagate_call("_ready")

	if parent.debug: return
	reset_scroll()

func _process(delta: float) -> void:
	if skin != null:
		skin.propagate_call("_process", [delta])
	if reset_timer == 0.0: return
	reset_timer -= delta * (Conductor.crotchet_mult * 0.25)
	if reset_timer <= 0.0 and reset_callback != null:
		reset_callback.call()

func reset_scroll(scroll: int = -1, tween: bool = false, tween_duration: float = 0.6) -> void:
	if scroll == -1: scroll = Settings.scroll
	var pos: int = 870

	match scroll:
		0: pos = 150 # Up
		1: pos = 870 # Down
		2: # Split (UD)
			var down: bool = get_index() >= 2
			pos = 870 if down else 150
		3: # Split (DU)
			var down: bool = get_index() <  2
			pos = 870 if down else 150

	if not tween: position.y = pos
	else:
		get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_CIRC) \
		.tween_property(self, "position:y", pos, tween_duration)

func glow_up(force: bool = true) -> void:
	if skin != null and skin.propagate_call("glow_up", [force]) == 0:
		return
	do_action(ActionType.GLOW, force)

func become_ghost(force: bool = true) -> void:
	if skin != null and skin.propagate_call("become_ghost", [force]) == 0:
		return
	do_action(ActionType.GHOST, force)

func become_static(force: bool = true) -> void:
	if skin.propagate_call("become_static", [force]) == 0:
		return
	do_action(ActionType.STATIC, force)

func do_action(action: int, force: bool = false) -> void:
	if skin != null and skin.propagate_call("do_action", [action, force]) == 0:
		return
	# default action player.
	# override with noteskin config file.
