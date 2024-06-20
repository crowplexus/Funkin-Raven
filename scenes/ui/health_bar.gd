extends TextureProgressBar

@export var icons: Array[CanvasItem] = []
@export var bop_interval: int = 1
var _has_icons: bool = false


func _ready() -> void:
	_has_icons = not icons.is_empty()
	if _has_icons:
		Conductor.ibeat_reached.connect(on_ibeat_reached)


func _exit_tree() -> void:
	if _has_icons:
		Conductor.ibeat_reached.disconnect(on_ibeat_reached)


func _process(delta: float) -> void:
	if not _has_icons:
		return

	for icon: CanvasItem in get_children():
		var lr_axis: int = -1 if fill_mode == ProgressBar.FILL_BEGIN_TO_END else 1
		var icon_health: float = value if icon.flip_h else 100 - value
		if lr_axis == -1:
			icon_health = 100 - value if icon.flip_h else value

		var hb_offset: float = 0.0 if lr_axis == -1 else size.x
		icon.frame = 1 if icon_health < 20 else 0
		icon.position.x = -(value * size.x / 100) + hb_offset
		icon.position.x *= lr_axis

		if icon.scale != Vector2.ONE:
			icon.scale = Vector2(
				lerpf(1.0, icon.scale.x, exp(-delta * 16)),
				lerpf(1.0, icon.scale.y, exp(-delta * 16))
			)


func on_ibeat_reached(ibeat: int) -> void:
	for icon: CanvasItem in get_children():
		if ibeat % bop_interval == 0:
			icon.scale *= 1.25


func set_player(player: int) -> void:
	match player:
		0: fill_mode = ProgressBar.FILL_END_TO_BEGIN
		1: fill_mode = ProgressBar.FILL_BEGIN_TO_END
