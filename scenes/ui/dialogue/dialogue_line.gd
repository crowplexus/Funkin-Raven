extends Resource
## Resource used for the dialogue writer to know what to write,
## how fast to write, and what sounds to play when writing.
class_name DialogueLine
## Text for the writter to write.
@export_multiline var text: String = ""
## Actor to appear when this line is active.
#@export var actor: Node
## Sound Blips that should be played when writing this line
@export var blips: Array[AudioStream] = []
## Speed of the writer when writing this line.
@export var speed: float = 30.0
func _to_string() -> String:
	return "(DialogueLine): \"%s\" - Speed: %s" % [ text, speed ]
## Since normally lines of text contain bbcode (e.g: [code][color=ColourName]text[/color][/code]),[br]
## this function returns the text with no bbcode tags included.
func get_pure_text() -> String:
	# regex i stole from the godot docs
	var regex: = RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(text, "", true)
## Creates a new line of dialogue, this function exists if you ever need to add lines via scripting[br]
## It is not recommended to rely only on scripting, using resources for dialogue is highly encouraged.
## [codeblock]
## # Writes a line saying "This is a line of dialogue", 50% speed and one audio blip
## var line_writer: = DialogueBox.new()
## var dialogue_line: = DialogueLine.write("This is a line of dialogue", 50.0, [load("res://assets/audio/sfx/dialogue/pixelText.ogg")])
## line_writer.lines.append(dialogue_line)
## [/codeblock]
static func write(dialogue_text: String, writing_speed: float = 30.0, writing_blips: Array[AudioStream] = []) -> DialogueLine:
	var new_line: = DialogueLine.new()
	new_line.text = dialogue_text
	new_line.speed = writing_speed
	new_line.blips = writing_blips
	return new_line
