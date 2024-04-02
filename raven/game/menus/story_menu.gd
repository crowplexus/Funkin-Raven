extends Node2D

@onready var week_labels: Control = $"ui/week_labels"
@onready var tracklist_label: Label = $"ui/labels/tracklist"
@onready var tagline_label: Label = $"ui/labels/level_label"

@onready var yellow: ColorRect = $"ui/yellow"

@onready var difficulty_spr: Sprite2D = $"difficulty"
@onready var arrow_left_spr: AnimatedSprite2D = $"difficulty/arrow1"
@onready var arrow_right_spr: AnimatedSprite2D = $"difficulty/arrow2"

@export var song_data: SongDatabase = preload("res://raven/resources/play/default_songs.tres")

var selected: int = 0
var alternative: int = 0
var weeks: Array[SongPack] = []
var locks: Array[int] = []
var _selected: bool = false

func _ready():
	if not SoundBoard.bg_tracks.playing:
		SoundBoard.play_track(load("res://assets/audio/bgm/freakyMenu.ogg"))
	FPS.texts.position.y = $ui/yellow.position.y
	
	weeks = song_data.song_packs
	generate_week_list()

func generate_week_list():
	while week_labels.get_child_count() != 0:
		var item = week_labels.get_child(0)
		week_labels.remove_child(item)
		item.queue_free()
	
	for i: int in weeks.size():
		var week_data: = weeks[i] as SongPack
		
		var week_sprite: = $"template_week".duplicate() as Sprite2D
		week_sprite.texture = week_data.image
		week_sprite.position.y += (week_sprite.texture.get_height() + 20) * i
		week_labels.add_child(week_sprite)
		week_sprite.visible = true
		
		if week_data.locked:
			var lock: = $"difficulty/arrow1".duplicate() as AnimatedSprite2D
			lock.play("lock")
			lock.frame = 0
			week_sprite.add_child(lock)
			lock.position.x = week_sprite.texture.get_width() * 0.62
			locks.append(i)
	
	selected = 0
	alternative = weeks[selected].difficulties.find(
		weeks[selected].difficulties.back())
	update_selection()

func _process(delta: float):
	for week_spr: Sprite2D in week_labels.get_children():
		var index: int = week_spr.get_index() - selected
		var next_y: float = (index * 120) + 525
		week_spr.position.y = Tools.lerp_fix(week_spr.position.y, next_y, delta, 15)
		week_spr.visible = (
			week_spr.position.y > get_viewport_rect().size.y * 0.5 and
			week_spr.position.y < get_viewport_rect().size.y + 5.0
		)

func play_week():
	if PlayField.play_manager == null:
		PlayField.play_manager = PlayManager.new(0, selected)
	else:
		PlayField.play_manager.play_mode = 0
		PlayField.play_manager.current_week = selected
	
	var cur_song: int = PlayField.play_manager.cur_song
	PlayField.play_manager.playlist = weeks[selected].songs.duplicate()
	
	var da_diff: String = weeks[selected].difficulties[alternative]
	PlayManager.set_song(PlayField.play_manager.playlist[cur_song], da_diff)
	SoundBoard.stop_tracks()
	Tools.switch_scene(load("res://raven/game/gameplay.tscn"))

func _unhandled_key_input(e: InputEvent):
	if _selected: return
	
	if e.is_released():
		arrow_left_spr.play("arrow left")
		arrow_right_spr.play("arrow right")
	
	var ud_axis: int = int( Input.get_axis("ui_up", "ui_down") )
	var lr_axis: int = int( Input.get_axis("ui_left", "ui_right") )
	if ud_axis != 0: update_selection(ud_axis)
	if lr_axis != 0:
		update_alternative(lr_axis)
		var dir: String = "left" if lr_axis == -1 else "right"
		var node: CanvasItem = arrow_left_spr if lr_axis == -1 else arrow_right_spr
		if node != null and e.is_pressed() or e.is_released():
			node.play("arrow " + dir + " push")
	
	if not e.pressed: return
	
	if locks.find(selected) == -1 and e.is_action("ui_accept"):
		SoundBoard.play_sfx(Menu2D.CONFIRM_SOUND)
		_selected = true
		play_week()
	
	if e.is_action("ui_cancel"):
		_selected = true
		Tools.switch_scene(load("res://raven/game/menus/main_menu.tscn"))

func update_selection(new: int = 0):
	selected = wrapi(selected + new, 0, weeks.size())
	if new != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	
	for i: int in week_labels.get_child_count():
		var spr: = week_labels.get_child(i) as Sprite2D
		spr.modulate.a = 0.6
		if i == selected and locks.find(i) == -1:
			spr.modulate.a = 1.0
	
	difficulty_spr.visible = locks.find(selected) == -1
	update_alternative()
	update_tracklist()
	tagline_label.text = weeks[selected].tagline.to_upper()

func update_alternative(new: int = 0):
	alternative = wrapi(alternative + new, 0, weeks[selected].difficulties.size())
	if new != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	
	if difficulty_spr.visible: # no reason to change if it's not visible
		var _diff: String = weeks[selected].difficulties[alternative]
		var path: String = "res://assets/images/menus/story/difficulties/%s.png" % _diff
		if ResourceLoader.exists(path):
			var diff_texture: Texture2D = load(path)
			difficulty_spr.texture = diff_texture

func update_tracklist():
	var text: String = "- TRACKS -\n\n"
	for i: int in weeks[selected].songs.size():
		var song: StringName = weeks[selected].songs[i].name
		text += song.to_upper()
		if i != weeks[selected].songs.size()-1:
			text += "\n"
	tracklist_label.text = text

func _exit_tree():
	FPS.texts.position.y = 0

func tween_or_do(item: CanvasItem, property: String, value: Variant, duration: float, tween: Tween):
	if Settings.skip_transitions:
		item.set_indexed(property, value) 
	else:
		tween.tween_property(item, property, value, duration)
		tween.finished.connect(tween.unreference)
