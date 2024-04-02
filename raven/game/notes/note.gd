class_name Note extends Node2D

# TODO: skinning?
@export var data: NoteData
@export var sustain_frames:SpriteFrames
@export var debug: bool = false
@export var force_splash: bool = false

var arrow:Node2D # i made this not an onready for more control.
var clip_rect: Control
var og_len: float = 0.0

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

#region Getters
var rel_time: float:
	get: return data.time - Conductor.time if data != null else NAN
var is_sustain: bool:
	get: return data != null and data.s_len > 0.0
var sustain_score: int:
	get:
		var scores: Array[int] = [0, 10, 20, 30, 40, 50]
		return scores.pick_random()
var down: bool:
	get:
		var v: bool = false
		if not debug:
			match Settings.scroll:
				1: v = true
				2: v = data.dir >= 2
				3: v = data.dir <  2
				_: v = false
		return v
var scroll: int:
	get: return -1 if down else 1
var can_hit: bool:
	get:
		if debug or (is_sustain and missed): return false
		var lowest: float = Highscore.worst_judgement()[1]
		return data != null and (data.time - Conductor.time) < lowest and not is_late

var receptor: Receptor:
	get:
		var strum_check: bool = $"../../" != null and $"../../" is NoteField 
		if strum_check:
			var rec: Receptor = $"../../".receptors.get_child(data.dir) as Receptor
			return rec if data != null and rec != null else null
		return null
var anim_prefix: String:
	get: return NoteData.color_to_str(data.dir) if data != null else "green"

var do_follow: bool = false
#endregion

#region Callbacks
func on_hit(): pass
func on_miss(): pass
func splash(): pass
#endregion

func _process(delta: float):
	if debug or rel_time == NAN: return
	
	if do_follow:
		position = receptor.position
		if not was_hit:
			position.y += rel_time * (800 * absf(receptor.speed)) / absf(receptor.scale.y) * scroll
	
	if clip_rect != null:
		if was_hit:
			# i hate that i have to do this but it's fine @crowplexus
			arrow.visible = false if not prevent_disposal else true
			data.s_len -= delta / absf(scale.y)
		
		var hold_size: float = 800 * absf(receptor.speed) * data.s_len - 10
		if clip_rect.size.y != hold_size:
			clip_rect.size.y = hold_size
		
		if data.s_len < 0.0:
			if receptor != null and  $"../../".is_cpu: receptor.queue_anim("static", true)
			queue_free()
			return
	
	var notefield: NoteField = receptor.parent
	if notefield == null: return
	if notefield.is_cpu:
		if rel_time <= 0.0:
			var force: bool = arrow.visible or Conductor.step % 2 == 0
			receptor.play_anim("confirm", force)
			receptor.reset_timer = (1 * Conductor.stepc) + data.s_len
			if force: notefield.hit_behavior.call(self)
	else:
		var late_delay: float = 0.15
		is_late = rel_time <= Highscore.best_judgement()[1] - late_delay
		if not was_hit and is_late:
			if not missed: notefield.miss_behavior.call(self, data.dir)
		if rel_time <= -( .15 + og_len * receptor.speed):
			queue_free()
