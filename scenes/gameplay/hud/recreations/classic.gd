extends GameHUD

@onready var health_bar: TextureProgressBar = $"health_bar"
@onready var icon_animation: AnimationPlayer = $"health_bar/animation_player"
@onready var status_label: Label = $"status_label"

@export var icon_bump_interval: int = 1
@export var health_bar_icons: Array[CanvasItem] = []

func _ready() -> void:
	reset_positions()
	if get_tree().current_scene.name == "gameplay":
		for field: NoteField in get_tree().current_scene.note_fields:
			field.position.x -= 25

	setup_healthbar()
	Conductor.ibeat_reached.connect(icon_bump)

func reset_positions() -> void:
	match Preferences.scroll_direction:
		0:
			health_bar.position.y = 678
			status_label.position.y = 110
		1:
			health_bar.position.y = 80
			status_label.position.y = 110

func _process(_delta: float) -> void:
	if not health_bar_icons.is_empty():
		move_icons()

func _exit_tree() -> void:
	if Conductor.ibeat_reached.is_connected(icon_bump):
		Conductor.ibeat_reached.disconnect(icon_bump)

#region Health and Icons

func setup_healthbar() -> void:
	var stage: StageBG = get_tree().current_scene.get("stage")
	if stage:
		# very messy icon stuff
		var char_icons: Array[HealthIcon] = [null, null]
		if stage.has_node("player2") and stage.get_node("player2") is Character:
			char_icons[0] = stage.get_node("player2").health_icon
		if stage.has_node("player1") and stage.get_node("player1") is Character:
			char_icons[1] = stage.get_node("player1").health_icon
		set_icons(char_icons)

func set_icons(icons: Array[HealthIcon]) -> void:
	for i: int in health_bar_icons.size():
		var ico: Sprite2D = health_bar_icons[i]
		if is_instance_valid(icons[i]):
			ico.texture = icons[i].texture
			ico.texture_filter = icons[i].filter
			ico.hframes = icons[i].hframes
			ico.vframes = icons[i].vframes
			ico.scale = icons[i].scale

func icon_bump(ibeat: int) -> void:
	if ibeat % icon_bump_interval == 0:
		icon_animation.seek(0.0)
		icon_animation.play("bump")

func set_player(player: int) -> void:
	match player:
		0: health_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		1: health_bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END

func get_health(next: float, current: float, delta: float) -> float:
	return lerpf(current, next, exp(-delta * 128))

func move_icons() -> void:
	for icon: CanvasItem in health_bar_icons:
		var lr_axis: int = -1 if health_bar.fill_mode == ProgressBar.FILL_BEGIN_TO_END else 1
		var icon_health: float = health_bar.value if icon.flip_h else 100 - health_bar.value
		if lr_axis == -1:
			icon_health = 100 - health_bar.value if icon.flip_h else health_bar.value
		var hb_offset: float = 0.0 if lr_axis == -1 else health_bar.size.x
		icon.frame = 1 if icon_health < 20 and icon.hframes == 2 else 0
		icon.position.x = -(health_bar.value * health_bar.size.x / 100) + hb_offset
		icon.position.x *= lr_axis

#endregion

func update_score_text(tally: Tally, _is_tap: bool) -> void:
	if tally.invalid == true:
		status_label.text = "Invalid Score"
		return
	status_label.text = "Score:%s" % tally.score
