@tool extends Control
class_name Alphabet

@export var texture: SpriteFrames = preload("res://assets/fonts/bold.res")
@export var allowed_letters: String = "abcdefghijklmnopqrstuvwxyz"
@export var allowed_symbols: String = "0123456789!@#$%&*():;+=<>-_"
@export var uppercase_suffix: String = ""
@export var lowercase_suffix: String = ""

@export_enum("Left:0", "Center:1", "Right:2")
var horizontal_alignment: int = 0:
	set(new_align):
		horizontal_alignment = new_align
		set_horizontal_alignment(new_align)
@export_enum("Top:0", "Center:1", "Bottom:2")
var vertical_alignment: int = 0:
	set(new_align):
		vertical_alignment = new_align
		set_vertical_alignment(new_align)
@export var x_per_space: int = 60
@export var y_per_roll: int = 80

@export_multiline var text: String:
	set(new_text):
		clear_glyphs()
		gen_glyphs(new_text.replace("\\n", "\n"))
		text = new_text

@export_category("Menu Config")

@export var is_menu: bool = false
@export var spacing: Vector2 = Vector2(20, 120)
@export var origin: Vector2 = Vector2.ZERO
@export var change_x: bool = true
@export var change_y: bool = true
@export var menu_target: int = 0

var glyphs_pos: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	if is_menu:
		if change_x:
			position.x = lerpf(origin.x + (menu_target * spacing.x), position.x, exp(-delta * 10))
		if change_y:
			var scaled_target: float = remap(menu_target, 0, 1, 0, 1.3)
			position.y = lerpf(origin.y + (scaled_target * spacing.y) + (size.y * 0.48), position.y, exp(-delta * 10))


func gen_glyphs(new_text: String) -> void:
	var pos: Vector2 = Vector2.ZERO
	var line: Control = Control.new()
	var _spaces: int = 0
	var _rows: int = 0

	for i: int in new_text.length():
		var character: String = new_text[i]
		line.name = "line_%s" % _rows
		if character.is_empty():
			continue
		if character == "\n":
			add_child(line)
			_rows += 1
			pos.x = 0
			pos.y += y_per_roll #* rows
			line = Control.new()
			line.name = "line_%s" % _rows
			continue
		if character == " ":
			_spaces += 1
			pos.x += x_per_space #* _spaces
			continue
		var glyph_animation: String = get_animation(character)
		if not glyph_animation.is_empty():
			var tex: Texture2D = texture.get_frame_texture(glyph_animation, 0)
			var glyph: AnimatedSprite2D = AnimatedSprite2D.new()
			glyph.name = character.to_lower() + str(line.get_child_count())
			glyph.offset = get_animation_offset(character)
			glyph.sprite_frames = texture
			glyph.position = pos
			glyph.play(glyph_animation)
			pos.x += tex.get_width()
			#pos.y += tex.get_height()
			#line.size += Vector2(tex.get_width(), tex.get_height())
			line.size.x += tex.get_width()
			line.add_child(glyph)
	add_child(line)
	glyphs_pos = pos
	set_horizontal_alignment(horizontal_alignment)
	set_vertical_alignment  (vertical_alignment)


func clear_glyphs() -> void:
	for i: CanvasItem in get_children():
		i.queue_free()


func get_line_count() -> int:
	return get_child_count()

func set_horizontal_alignment(id: int) -> void:
	for line: Control in get_children():
		match id:
			0: line.position.x = 0.0
			1: line.position.x = (size.x - line.size.x) * 0.5
			2: line.position.x = (size.x - line.size.x)
		line.position.y *= scale.x * line.scale.x


func set_vertical_alignment(id: int) -> void:
	for line: Control in get_children():
		match id:
			0: line.position.y = 0.0
			1: line.position.y = (size.y - line.size.y) * 0.5
			2: line.position.y = (size.y - line.size.y)
		line.position.y *= scale.y * line.scale.y


func get_animation(character: String) -> String:
	match character:
		".": return "period"
		",": return "comma"
		":": return "colon"
		";": return "semicolon"
		"'": return "singlequote"
		"\\": return "backslash"
		"%": return "percent"
		"/": return "slash"
		"&": return "and"
		"!": return "exclamation mark"
		"?": return "question mark"
		_:
			if allowed_letters.find(character.to_lower()) != -1:
				if character != character.to_lower():
					return "%s" % [ character.to_upper() + uppercase_suffix ]
				else:
					return "%s" % [ character.to_upper() + lowercase_suffix ]
			elif allowed_symbols.find(character) != -1:
				return "%s" % character
			return ""


func get_animation_offset(character: String) -> Vector2:
	match character:
		".": return Vector2(-10, 20)
		",": return Vector2(-5, 15)
		"'": return Vector2(-10, -15)
		_: return Vector2.ZERO
