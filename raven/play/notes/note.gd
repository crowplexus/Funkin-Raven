class_name Note extends Node2D

static func _placeholder_sustain() -> Texture2D:
	var tex: = PlaceholderTexture2D.new()
	tex.size.x = 50
	return tex

@export var data: Dictionary = { "debug": false, }
@export var sustain_data: Dictionary = {
	"tail_texture": Note._placeholder_sustain(),
	"hold_texture": Note._placeholder_sustain(),
}
@export var force_splash: bool = false

var arrow: Node2D # i made this not an onready for more control. @srthero278
var splash: Node2D
var clip_rect: Control
var og_len: float = 0.0
var receptor: Receptor

var selected: bool = false:
	set(v):
		selected = v
		modulate.v = 1.0 + 0.5 * float(v)

var is_late: bool = false
var was_hit: bool = false
var missed: bool = false:
	set(v):
		missed = v
		modulate.a = 0.3
var prevent_disposal: bool = false
## Coyote Timer for regrabbing hold notes
var hold_coyote: float = 0.0
var late_hold: bool = false

var judgement: Dictionary = Highscore.judgements.back()

#region Getters

func get_time_offseted() -> float:
	return data.time + Settings.note_offset

func get_time_relative() -> float:
	return get_time_offseted() - Conductor.time

var rel_time: float:
	get: return get_time_relative() if data != null else NAN

var is_sustain: bool:
	get: return data != null and data.s_len > 0.0

## Dictates your Scroll Arrangement[br]

var scroll: int:
	get:
		var arrangement: int = 1
		if data.has("force_scroll") and data["force_scroll"] is int:
			return data["force_scroll"]
		if not data.debug:
			match Settings.scroll:
				0: arrangement = 1
				1: arrangement = -1
		return arrangement

var can_hit: bool:
	get:
		if data.debug or (is_sustain and missed): return false
		var lowest: float = Highscore.worst_judgement().timing
		return data != null and (get_time_offseted() - Conductor.time) < lowest and not is_late

var do_follow: bool = false
#endregion

#region Callbacks
func on_hit() -> void: pass
func on_miss() -> void: pass
func pop_splash() -> void: pass
#endregion

func _ready() -> void:
	if data.debug == true:
		set_process(false)

	if Settings.scroll == 2:
		if data.has("override_middle") and data.override_middle is int:
			data["force_scroll"] = data["override_middle"]
		else:
			data["force_scroll"] = -1 if Conductor.step % 2 == 0 else 1

func _process(delta: float) -> void:
	if data.debug == true: return # just in case

	if do_follow:
		position = receptor.position
		if not was_hit:
			position.y += rel_time * (800.0 * absf(receptor.speed)) / absf(receptor.scale.y) * scroll

	if is_sustain and clip_rect != null:
		if was_hit:
			# i hate that i have to do this but it's fine @crowplexus
			arrow.visible = false if not prevent_disposal else true
			if rel_time < -0 and not late_hold:
				data.s_len += rel_time
				late_hold = true
			data.s_len -= delta / absf(scale.y)

		update_sustain_len(data.s_len)
		if data.s_len < 0.0:
			if is_instance_valid(receptor) and not receptor.parent.is_cpu:
				receptor.display_hold_cover(true)
			queue_free()
			return

	if receptor.parent != null and not missed:
		if is_sustain and was_hit and not receptor.parent.is_cpu:
			receptor.parent._handle_hold_behaviour(self, delta)
		receptor.parent._handle_note_behaviour(self)

func update_sustain_len(new_len: float) -> void:
	if not is_sustain:
		return

	var hold_size: float = (800.0 * absf(receptor.speed)) * new_len
	if clip_rect.size.y != hold_size:
		clip_rect.size.y = hold_size
