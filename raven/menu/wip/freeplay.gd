extends Menu2D
# freeplay rewrite but like awesome

@onready var bg: Sprite2D = $"bg"
@onready var song_group: Control = $"ui/songs"
@onready var icon_group: Control = $"ui/icons"
@export  var data_to_use: SongDatabase

var song_list: Array = []
var categories: Dictionary = {}
var category: StringName = ""

var _display_stats: bool = false
var _selected: bool = false
var _bg_tween: Tween
var _visi_tween: Tween

func _ready() -> void:
	await RenderingServer.frame_post_draw
	if not SoundBoard.bg_tracks.playing:
		SoundBoard.play_track(Menu2D.DEFAULT_MENU_MUSIC)
	categories = data_to_use.make_category_list()
	category = categories.keys().front()
	song_list = categories[category]
	create_items()

func _process(_delta: float) -> void:
	if not song_list.is_empty():
		for i: int in song_group.get_child_count():
			var item: = song_group.get_child(i) as Alphabet
			var icon: = icon_group.get_child(i) as Sprite2D
			if icon == null: continue
			var last: = item.get_child(item.get_child_count() - 1)
			icon.position = Vector2(
				(last.global_position.x + item.end_position.x + 90),
				(last.global_position.y + item.end_position.y + 30)
			)
			icon.modulate.a = item.modulate.a

func update_selection(new: int = 0) -> void:
	super(new)

	if new != 0: SoundBoard.play_sfx(SCROLL_SOUND)
	if _visi_tween != null: _visi_tween.stop()
	_visi_tween = create_tween().set_ease(Tween.EASE_OUT_IN)
	_visi_tween.set_parallel(true)

	for i: int in song_group.get_child_count():
		var let: Alphabet = song_group.get_child(i) as Alphabet
		var target_vis: float = 1.0 if i == selected else 0.6
		_visi_tween.tween_property(let, "modulate:a", target_vis, 0.1)
		let.item_id = i - selected

	if is_instance_valid(bg):
		if _bg_tween != null: _bg_tween.stop()
		_bg_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		_bg_tween.tween_property(bg, "modulate", song_list[selected].color, 0.5)

	hoptions = song_list[selected].difficulties
	if alternative >= hoptions.size():
		alternative = hoptions.size() - 1
	update_alternative()

func update_alternative(new: int = 0) -> void:
	super(new)
	var text_str: String = "< %s >" if hoptions.size() > 1 else "%s"
	if new != 0 and hoptions.size() > 1: SoundBoard.play_sfx(SCROLL_SOUND)
	#diff_text.text = "\"%s\"\n" % song_list[selected].name
	#diff_text.text += text_str % tr(song_list[selected].difficulties[alternative].to_lower())
	#update_score_display()

func create_items() -> void:
	while song_group.get_child_count() != 0:
		var song_alpha = song_group.get_child(0)
		song_group.remove_child(song_alpha)
		song_group.queue_free()

	while icon_group.get_child_count() != 0:
		var song_icon  = icon_group.get_child(0)
		icon_group.remove_child(song_icon)
		song_icon.queue_free()

	for i: int in song_list.size():
		var song_thing: Alphabet = Alphabet.new()
		song_thing.text = song_list[i].name
		song_thing.lock_axis.x = get_viewport().size.x * 0.8
		song_thing.is_menu_item = true
		song_thing.spacing.y = 100
		song_thing.alignment = 2
		song_thing.item_id = i
		song_group.add_child(song_thing)

		if category != "":
			var icon_thing: Sprite2D = Sprite2D.new()
			if song_list[i].icon != null:
				icon_thing.texture = song_list[i].icon
			icon_thing.hframes = 2
			icon_group.add_child(icon_thing)

	voptions = song_list
	update_selection()
