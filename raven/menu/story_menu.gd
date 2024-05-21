extends Menu2D

@onready var level_labels: Control = $"ui/level_labels"
@onready var tracklist_label: Label = $"ui/labels/tracklist"
@onready var tagline_label: Label = $"ui/labels/level_label"

@onready var yellow: ColorRect = $"ui/yellow"

@onready var diff_sprite: Sprite2D = $"difficulty"
@onready var arrowl_sprite: AnimatedSprite2D = $"difficulty/arrow1"
@onready var arrowr_sprite: AnimatedSprite2D = $"difficulty/arrow2"

@export var song_data: SongDatabase = preload("res://assets/data/default_songs.tres")

var levels: Array[SongPack] = []
var locks: Array[int] = []

var _diff_tween: Tween
var _selected: bool = false

func _ready() -> void:
	can_open_options = true
	if not SoundBoard.bg_tracks.playing:
		SoundBoard.play_track(load("res://assets/audio/bgm/freakyMenu.ogg"))
	FPS.perf_text.position.y = $ui/yellow.position.y

	levels = song_data.song_packs
	generate_level_list()

func generate_level_list() -> void:
	while level_labels.get_child_count() != 0:
		var item: Sprite2D = level_labels.get_child(0)
		level_labels.remove_child(item)
		item.queue_free()

	for i: int in levels.size():
		var level_data: = levels[i] as SongPack

		var level_sprite: = Sprite2D.new()
		level_sprite.texture = level_data.image
		level_labels.add_child(level_sprite)
		level_sprite.global_position = $"template_level".global_position

		if level_data.locked:
			var lock: Sprite2D = Sprite2D.new()
			lock.texture = load("res://assets/menus/story/lock.png")
			lock.frame = 0
			level_sprite.add_child(lock)
			lock.position.x = level_sprite.texture.get_width() * 0.62
			locks.append(i)

	voptions = levels
	alternative = levels[selected].difficulties.find(
		levels[selected].difficulties.back())

	selected = 0
	update_selection()

func _process(_delta: float) -> void:
	for level_spr: Sprite2D in level_labels.get_children():
		var index: int = level_spr.get_index() - selected
		var next_y: float = (index * 120) + 85
		level_spr.position.y = Tools.exp_lerp(level_spr.position.y, next_y, 15)

func play_level() -> void:
	if PlayField.play_manager == null:
		PlayField.play_manager = Progression.new(0, selected)
	else:
		PlayField.play_manager.play_mode = 0
		PlayField.play_manager.current_level = selected

	var cur_song: int = PlayField.play_manager.cur_song
	PlayField.play_manager.playlist = levels[selected].songs.duplicate()

	var da_diff: String = levels[selected].difficulties[alternative]
	Progression.set_song(PlayField.play_manager.playlist[cur_song], da_diff)
	SoundBoard.stop_tracks()
	Tools.switch_scene(load("res://raven/play/gameplay.tscn"))

func _unhandled_key_input(e: InputEvent) -> void:
	if _selected: return

	if can_open_options:
		if Input.is_key_label_pressed(KEY_MENU):
			self.process_mode = Node.PROCESS_MODE_DISABLED
			add_child(Tools.get_options_window())

	if e.is_released():
		arrowl_sprite.play("leftIdle")
		arrowr_sprite.play("rightIdle")

	var ud: int = int( Input.get_axis("ui_up", "ui_down") )
	var lr: int = int( Input.get_axis("ui_left", "ui_right") )
	if ud: update_selection(ud)
	if lr:
		update_alternative(lr)
		var dir: String = "left" if lr == -1 else "right"
		var node: CanvasItem = arrowl_sprite if lr == -1 else arrowr_sprite
		if node != null and e.is_pressed() or e.is_released():
			node.play(dir + "Confirm")

	if Input.is_action_just_pressed("ui_accept") and locks.find(selected) == -1:
		SoundBoard.play_sfx(Menu2D.CONFIRM_SOUND)
		_selected = true
		play_level()

	if Input.is_action_just_pressed("ui_cancel"):
		_selected = true
		Tools.switch_scene(load("res://raven/menu/main_menu.tscn"))

func update_selection(new: int = 0) -> void:
	super(new)
	if new != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)

	for i: int in level_labels.get_child_count():
		var spr: = level_labels.get_child(i) as Sprite2D
		spr.modulate.a = 0.6
		if i == selected and locks.find(i) == -1:
			spr.modulate.a = 1.0

	hoptions = levels[selected].difficulties
	diff_sprite.visible = locks.find(selected) == -1
	tagline_label.text = levels[selected].tagline.to_upper()
	update_alternative()
	update_tracklist()

func update_alternative(new: int = 0) -> void:
	super(new)
	if new != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)

	if diff_sprite.visible: # no reason to change if it's not visible
		if _diff_tween != null: _diff_tween.kill()

		_diff_tween = create_tween().set_ease(Tween.EASE_IN)
		_diff_tween.set_trans(Tween.TRANS_QUAD)
		_diff_tween.set_parallel(true)

		var _diff: String = levels[selected].difficulties[alternative]
		var path: String = "res://assets/menus/story/difficulties/%s.png" % _diff
		if ResourceLoader.exists(path):
			var diff_texture: = load(path) as Texture2D
			var left_x: float = diff_sprite.global_position.x - diff_texture.get_width() * 0.5
			var right_x: float = diff_sprite.global_position.x + diff_texture.get_width() * 0.5

			diff_sprite.texture = diff_texture
			tween_or_do(arrowl_sprite, "global_position:x", left_x  - 50, 0.15, _diff_tween)
			tween_or_do(arrowr_sprite, "global_position:x", right_x + 50, 0.15, _diff_tween)

func update_tracklist() -> void:
	var text: String = "- TRACKS -\n\n"
	for i: int in levels[selected].songs.size():
		var song: StringName = levels[selected].songs[i].name
		text += song.to_upper()
		if i != levels[selected].songs.size()-1:
			text += "\n"
	tracklist_label.text = text

func _exit_tree() -> void:
	FPS.perf_text.position.y = 0

func tween_or_do(item: CanvasItem, property: String, value: Variant, duration: float, tween: Tween) -> void:
	if Settings.skip_transitions:
		item.set_indexed(property, value)
	else:
		tween.tween_property(item, property, value, duration)
		tween.finished.connect(tween.unreference)
