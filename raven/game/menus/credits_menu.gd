extends Menu2D

@onready var usernames: Control = $"bar/texts"
@onready var descriptor: Label = $"descriptor"
@onready var category_name: Label = $"category"
@onready var bar: Sprite2D = $"bar"

@export var categories: Dictionary = {
	"Funkin' Raven": [],
	"Funkin' Crew" : [],
}
var data: Array:
	get: return categories[ category ]
var category: StringName:
	get: return categories.keys()[1-alternative]

func _ready():
	await RenderingServer.frame_post_draw
	if not SoundBoard.bg_tracks.playing:
		SoundBoard.play_track(load("res://assets/audio/bgm/freakyMenu.ogg"))
	
	total_selectors = data.size()
	total_alternatives = categories.keys().size()
	update_alternative()

func _process(_delta: float):
	for i: int in usernames.get_child_count():
		var let: = usernames.get_child(i) as Alphabet
		let.lock_axis.x = 45 + (-(10 * let.get_index()) - bar.scale.x)
	
	if (Input.is_action_just_pressed("ui_accept") and
		data[selected] is Contributor and
		not data[selected].redirect_url.is_empty()):
		
		SoundBoard.play_sfx(Menu2D.CONFIRM_SOUND)
		OS.shell_open( data[selected].redirect_url )

func create_items():
	while usernames.get_child_count() != 0:
		var item = usernames.get_child(0)
		usernames.remove_child(item)
		item.queue_free()
	
	category_name.text = "< " + category + " >"
	category_name.size.x = 20 * category_name.text.length()
	var port_end: = get_viewport_rect().end
	await RenderingServer.frame_post_draw
	category_name.position.x = (port_end.x - category_name.size.x) - 5
	category_name.size.y = 64
	
	var id: int = 0
	for i in data:
		if not i is Contributor:
			print_debug( type_string(typeof(i)) )
			continue
		
		var letter: Alphabet = Alphabet.new()
		
		letter.item_id = id
		letter.is_menu_item = true
		letter.scale = Vector2(0.9, 0.9)
		letter.item_offset.y = -50
		letter.spacing.y = 120
		
		#letter.size = Vector2(407, 70)
		letter.text = i.username
		letter.modulate.a = 0.6
		
		usernames.add_child(letter)
		id += 1
	
	selected = 0
	update_selection()

func update_selection(new: int = 0):
	super(new)
	
	if new != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	for i in usernames.get_child_count():
		var let: Alphabet = usernames.get_child(i) as Alphabet
		var visi_val: float = 0.3
		if i == selected: visi_val = 1.0
		elif i == selected - 1 or i == selected + 1:
			visi_val = 0.6
		
		let.modulate.a = visi_val
		let.item_id = i - selected
	
	update_descriptor()

func update_alternative(new: int = 0):
	super(new)
	if new != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	create_items()

func update_descriptor():
	descriptor.text = data[selected].description
	await RenderingServer.frame_post_draw
	descriptor.position.y = get_viewport_rect().size.y - descriptor.size.y - 20
