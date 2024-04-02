@tool class_name Alphabet extends Control

enum LetterType { NORMAL, BOLD }

@export_category("Alphabet")

const X_PER_SPACE: float = 40
const Y_PER_ROW: float = 80

@export var texture: SpriteFrames = preload("res://assets/fonts/alphabet.xml")
@export var type: LetterType = LetterType.BOLD

@export_multiline var text: String:
	set(v):
		text = v.replace("\\n", "\n")
		for i in get_children(): i.queue_free()
		if not text.is_empty(): _generate_txt(text)

@export_enum("Left:0", "Center:1", "Right:2")
var alignment: int = 0:
	set(v):
		alignment = v
		update_alignment(v)

@export_category("Menus")

@export var is_menu_item: bool = false
@export var item_offset: Vector2 = Vector2.ZERO
@export var lock_axis: Vector2 = Vector2(-1, -1)
@export var spacing: Vector2 = Vector2(30, 150)
@export var item_id: int = 0

var end_position: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if is_menu_item:
		var item_pos: float = (item_id * spacing.x) + 100
		var remap_y: float = remap(item_id, 0, 1, 0, 1.1)
		var menu_lerp: Vector2 = Vector2(
			Tools.lerp_fix(position.x, item_pos + item_offset.x, delta, 9.6),
			Tools.lerp_fix(position.y, (remap_y * spacing.y) + \
				(Tools.SCREEN_SIZE.x * 0.28) + item_offset.y, delta, 9.6)
		)
		
		var view: = get_viewport_rect()
		var bounds: Vector2 = view.size * scale
		
		if lock_axis.x != -1: menu_lerp.x = lock_axis.x
		if lock_axis.y != -1: menu_lerp.y = lock_axis.y
		
		position = menu_lerp
		visible = (position.x > -(size.x * (view.end.x) * scale.x) and position.x < bounds.x / size.x
				or position.y > -(size.y * (view.end.y) * scale.y) and position.y < bounds.y / size.y)

func _generate_txt(new_text: String):
	var line: Control = Control.new()
	var letter_pos: Vector2 = Vector2.ZERO
	var text_content: PackedStringArray = new_text.split("")
	var rows: int = 0
	
	for i: int in new_text.split("").size():
		var _char: String = text_content[i]
		
		if _char == "\n":
			rows += 1
			letter_pos.x = 0
			letter_pos.y += Y_PER_ROW
			add_child(line)
			line = Control.new()
			continue
		
		if _char == " ":
			letter_pos.x += X_PER_SPACE
			continue
		
		var letter: AlphabetGlyph = AlphabetGlyph.new(texture, _char, type)
		letter.position = letter_pos * scale
		letter.offset.y -= (line.size.y - 60.0) * 0.5
		letter.row = rows
		if letter.visible:
			line.size += letter.texture_size
			letter_pos.x += letter.texture_size.x
		line.add_child(letter)
	add_child(line)
	
	end_position = letter_pos
	update_alignment(alignment)

func update_alignment(x: int = -1):
	if x == -1: x = alignment
	for i: Control in get_children():
		i.position.x = position.x
		match x:
			1: i.position.x += ((size.x - i.size.x) * 0.5)
			2: i.position.x += (size.x - i.size.x)
		i.position.x *= i.scale.x * scale.x
