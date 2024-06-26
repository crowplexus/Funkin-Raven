@tool extends Control
class_name Alphabet

@export var texture: SpriteFrames = preload("res://assets/fonts/alphabet.res")
@export var allowed_letters: String = "abcdefghijklmnopqrstuvwxyz"
@export var allowed_symbols: String = "0123456789!@#$%&*():;+=<>-_"

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
			glyph.sprite_frames = texture
			glyph.position = pos
			glyph.play(glyph_animation)
			pos.x += tex.get_width() * scale.x
			#pos.y += tex.get_height() * scale.y
			line.add_child(glyph)
	add_child(line)
	glyphs_pos = pos


func clear_glyphs() -> void:
	for i: CanvasItem in get_children():
		i.queue_free()


func get_animation(character: String) -> String:
	match character:
		_:
			if allowed_letters.find(character.to_lower()) != -1:
				return "%s bold" % character.to_upper()
			elif allowed_symbols.find(character) != -1:
				return "%s" % character
			return ""
