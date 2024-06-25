extends TextureProgressBar

@export var icons: Array[CanvasItem] = []
@export var bop_interval: int = 1


func _process(_delta: float) -> void:
	if icons.is_empty():
		return
	for icon: CanvasItem in icons:
		var lr_axis: int = -1 if fill_mode == ProgressBar.FILL_BEGIN_TO_END else 1
		var icon_health: float = value if icon.flip_h else 100 - value
		if lr_axis == -1:
			icon_health = 100 - value if icon.flip_h else value
		var hb_offset: float = 0.0 if lr_axis == -1 else size.x
		icon.frame = 1 if icon_health < 20 else 0
		icon.position.x = -(value * size.x / 100) + hb_offset
		icon.position.x *= lr_axis


func set_player(player: int) -> void:
	match player:
		0: fill_mode = ProgressBar.FILL_END_TO_BEGIN
		1: fill_mode = ProgressBar.FILL_BEGIN_TO_END
