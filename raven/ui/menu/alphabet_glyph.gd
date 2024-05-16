class_name AlphabetGlyph extends AnimatedSprite2D

const LETTERS: String = "qwertyuiopasdfghjklçzxcvbnm"
const SYMBOLS: String = "(){}[]\"!@#$%'*+-=_.,:;<>?^&\\/|~"
const NUMBERS: String = "1234567890"

var letter: StringName = ""
var _raw_letter: StringName = ""
var type: Alphabet.LetterType = Alphabet.LetterType.BOLD
var row: int = 0

var texture_size: Vector2:
	get:
		var ret: Vector2 = Vector2.ZERO
		if sprite_frames != null:
			var frame_tex: Texture2D = sprite_frames.get_frame_texture(letter, 0)
			ret = Vector2(frame_tex.get_width(), frame_tex.get_height())
		return ret

func _init(new_tex: SpriteFrames, let: StringName, ctype: Alphabet.LetterType) -> void:
	let = let.dedent()
	if let.is_empty():
		return

	self.centered = false
	var actual_letter: StringName = _format_animation(let)
	self.letter = actual_letter
	self._raw_letter = let
	self.type = ctype

	if new_tex != null:
		var frame_tex: Texture2D = new_tex.get_frame_texture(actual_letter, 0)
		if not letter.dedent().is_empty() and frame_tex != null:
			self.sprite_frames = new_tex

func _ready() -> void:
	if self.letter.is_empty(): return
	offset = _get_anim_offset(_raw_letter)
	play(self.letter)

func _format_animation(let: String) -> String:
	let = let.dedent()
	var suffix: String = "normal"
	if type == Alphabet.LetterType.BOLD:
		suffix = "bold"
	match let:
		"'": let = "apostrophe " + suffix
		".", "•": let = "period " + suffix
		"?": let = "question " + suffix
		"¿": let = "iquestion "  + suffix
		"{": let = "( " + suffix
		"}": let = ") " + suffix
		"[": let = "[ normal"
		"]": let = "] normal"
		"/": let = "forward slash normal"
		"\\": let = "back slash normal"
		",": let = "comma normal"
		"@": let = "@ normal"
		"_": let = "- normal"
		"#": let = "# normal"
		"'": let = "' normal"
		"%": let = "% normal"
		_:
			if let == null or let == "" or let == "\n": return ""
			var is_letter: bool = LETTERS.find(let.to_lower()) != -1
			var casing :String = " "+Alphabet.LetterType.keys()[type].to_lower()
			if type != Alphabet.LetterType.BOLD:
				if is_letter:
					if let.to_lower() != let: casing = " uppercase"
					else: " lowercase"
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
