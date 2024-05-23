class_name AlphabetGlyph extends AnimatedSprite2D

const LETTERS: String = "qwertyuiopasdfghjklçzxcvbnmáàâãéèêíìîóòôúùûçñ"
const SYMBOLS: String = "1234567890(){}[]\"!@#$%'*+-=_.,:;<>?^&\\/|~"

var letter: StringName = ""
var _raw_letter: StringName = ""
var _raw_texture: SpriteFrames
var row: int = 0

var texture_size: Vector2:
	get:
		var ret: Vector2 = Vector2.ZERO
		if sprite_frames != null:
			var frame_tex: Texture2D = sprite_frames.get_frame_texture(letter, 0)
			ret = Vector2(frame_tex.get_width(), frame_tex.get_height())
		return ret

func _init(new_tex: SpriteFrames, let: StringName) -> void:
	let = let.dedent()
	if let.is_empty():
		return

	var actual_letter: StringName = _format_animation(let)

	self.centered = false
	self.letter = actual_letter
	self._raw_texture = new_tex
	self._raw_letter = let

	if new_tex != null:
		var frame_tex: Texture2D = new_tex.get_frame_texture(actual_letter, 0)
		if not letter.dedent().is_empty() and frame_tex != null:
			self.sprite_frames = new_tex

func _ready() -> void:
	if self.letter.is_empty(): return
	offset = _get_anim_offset(_raw_letter)
	play(self.letter)

func copy() -> AlphabetGlyph:
	var copy: AlphabetGlyph = AlphabetGlyph.new(_raw_texture, _raw_letter)
	copy.position = self.position
	copy.offset = self.offset
	copy.row = self.row
	return copy

func _format_animation(let: String) -> String:
	let = let.dedent()
	match let:
		"'": let = "apostrophe normal"
		".", "•": let = "period normal"
		"!": let = "exclamation normal"
		"¡": let = "iexclamation normal"
		"?": let = "question normal"
		"¿": let = "iquestion normal"
		"/": let = "forward slash normal"
		"\\": let = "back slash normal"
		",": let = "comma normal"
		"'": let = "comma normal"
		'"': let = "quote normal"
		"{": let = "( normal"
		"}": let = ") normal"
		"[": let = "[ normal"
		"]": let = "] normal"
		"@": let = "@ normal"
		"&": let = "amp normal"
		"_": let = "- normal"
		"#": let = "# normal"
		"'": let = "' normal"
		"%": let = "% normal"
		_:
			if let == null or let == "" or let == "\n": return ""
			var casing: String = " normal"
			if LETTERS.find(let.to_lower()) != -1:
				if let.to_lower() != let: casing = " uppercase"
				else: casing = " lowercase"
			let = let.to_lower() + casing

	return let

func _get_anim_offset(let: String) -> Vector2:
	match let.dedent().to_lower():
		"ã", "ñ", "õ": return Vector2(0, -25)
		"á", "é", "í", "ó", "ú": return Vector2(0, -34)
		"â", "ê", "î", "ô", "û": return Vector2(0, -30)
		"-": return Vector2(0, 25)
		"_": return Vector2(0, 50)
		".", ",": return Vector2(0, 50)
		"?", "¿": return Vector2(0, -10)
		"•": return Vector2(0, 25)
		_: return Vector2.ZERO
