extends Resource
## Resource for Cutscenes which have dialogue.
class_name Conversation
## Dialogue Box scene that is going to be used[br]
## See the preloaded scene for an example of how it should look like structure-wise.
@export var box: PackedScene = preload("res://scenes/ui/dialogue/dialogue_box.tscn")
## Lines of text that are going to be displayed on the box's text writer.
@export var lines: Array[DialogueLine] = []
