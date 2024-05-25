@tool class_name Alphabet extends Control

const X_PER_SPACE: float = 40
const Y_PER_ROW: float = 80

@export_category("Text")

@export var texture: SpriteFrames = preload("res://assets/fonts/bitmap/alphabet.res")
@export var outline_size: int = 2
@export var character_spacing: int = 5

@export var outline_colour: Color = Color.BLACK:
	set(v):
		outline_colour = v
		if outline_size == 0: return
		for line: Control in get_children():
			for glyph: CanvasItem in line.get_children():
				if glyph.name.begins_with("outline_"):
					glyph.modulate = v

@export_enum("Don't:0", "Uppercase:1", "Lowercase:2")
var force_casing: int = 0:
	set(v):
		force_casing = v
		var new_txt: String = get_forced_casing(text)
		for i: Node in get_children(): i.queue_free()
		if not text.is_empty(): _generate_txt(new_txt)

@export_multiline var text: String:
	set(v):
		text = v.replace("\\n", "\n")
		for i: Node in get_children(): i.queue_free()
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

func _process(_delta: float) -> void:
	if is_menu_item:
		var item_pos: float = (item_id * spacing.x) + 100
		var remap_y: float = remap(item_id, 0, 1, 0, 1.1)
		var menu_lerp: Vector2 = Vector2(
			Tools.exp_lerp(position.x, item_pos + item_offset.x, 9.6),
			Tools.exp_lerp(position.y, (remap_y * spacing.y) + \
				(Tools.SCREEN_SIZE.x * 0.28) + item_offset.y, 9.6)
		)

		var view: = get_viewport_rect()
		var bounds: Vector2 = view.size * scale

		if lock_axis.x != -1: menu_lerp.x = lock_axis.x
		if lock_axis.y != -1: menu_lerp.y = lock_axis.y

		position = menu_lerp
		visible = (position.x > -(size.x * (view.end.x) * scale.x) and position.x < bounds.x / size.x
				or position.y > -(size.y * (view.end.y) * scale.y) and position.y < bounds.y / size.y)

func _generate_txt(new_text: String) -> void:
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

		if force_casing != 0:
			_char = get_forced_casing(_char, force_casing)

		var letter: AlphabetGlyph = AlphabetGlyph.new(texture, _char)
		letter.position = letter_pos * scale
		letter.row = rows
		if letter.visible:
			line.size += letter.texture_size
			letter_pos.x += letter.texture_size.x + character_spacing
		letter.offset = letter._get_anim_offset(_char)
		letter.offset.y -= letter.texture_size.y - 50
		line.add_child(letter)
		letter.name = "letter_%s_%s" % [_char, letter.get_index()]

		if outline_size > 0:
			var outline: AlphabetGlyph = letter.copy()
			outline.name = "outline_%s_%s" % [_char, letter.get_index()]
			outline.modulate = outline_colour
			#outline.scale *= 1 + outline_size * 2 / outline.texture.size.x
			outline.scale *= 0.5 * outline_size
			outline.position.y -= 5
			outline.position.x -= 3
			outline.z_index = letter.z_index -1
			line.add_child(outline)
	add_child(line)

	end_position = letter_pos
	update_alignment(alignment)

func update_alignment(x: int = -1) -> void:
	if x == -1: x = alignment
	for i: Control in get_children():
		i.position.x = position.x - 50
		match x:
			1: i.position.x += (size.x - i.size.x) * 0.5
			2: i.position.x += (size.x - i.size.x)
		i.position.x *= i.scale.x * scale.x

func get_forced_casing(text: String, casing_id: int = 0) -> String:
	var forced: String = text
	match casing_id:
		1: forced = text.to_upper()
		2: forced = text.to_lower()
	print_debug("getting casing, ", forced)
	return forced
