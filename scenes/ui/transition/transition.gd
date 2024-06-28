extends CanvasLayer

const ANIMATIONS: Dictionary = {
	"wipe": preload("res://scenes/ui/transition/animations/wipe_transition.tscn"),
	#"fade": preload("res://scenes/ui/transition/animations/fade_transition.tscn"),
	#"sticker": preload("res://scenes/ui/transition/animations/fnf_stickers.tscn"),
}


func play_in(animation: String = "wipe", speed: float = 1.0) -> void:
	if not animation in ANIMATIONS:
		animation = "wipe" # default
	var trans
	if not has_node(animation):
		trans = ANIMATIONS[animation].instantiate()
		trans.name = animation
		add_child(trans)
	else:
		trans = get_node(animation)
	trans.start.call_deferred(false, speed)
	await trans.finished


func play_out(animation: String = "wipe", speed: float = 1.0) -> void:
	if not animation in ANIMATIONS:
		animation = "wipe" # default
	var trans
	if not has_node(animation):
		trans = ANIMATIONS[animation].instantiate()
		trans.name = animation
		add_child(trans)
	else:
		trans = get_node(animation)
	trans.start.call_deferred(true, speed)
	await trans.finished
