extends Control

@onready var field: = $field

var note: int = 0
var player: int = 0
var binding: bool = false
var on_leave: Callable = func(): pass

var forbidden_keycodes: Array[Key] = [
	KEY_ESCAPE, KEY_ENTER, KEY_F7, KEY_PRINT
]

var temp_keybinds: Array = []

var instructions: String

func _ready():
	instructions = $label.text
	temp_keybinds = Settings.keybinds.duplicate()
	update_selected_note()
	update_text()

func _unhandled_key_input(e: InputEvent):
	if not e.pressed: return
	if not binding:
		var lr_diff: int = int( Input.get_axis("ui_left", "ui_right") )
		var ud_diff: int = int( Input.get_axis("ui_up", "ui_down") )
		if lr_diff != 0: update_selected_note(lr_diff)
		if ud_diff != 0: update_selected_player(ud_diff)
		
		if Input.is_action_just_pressed("ui_accept"):
			binding = true
			field.receptors.get_child(note).play_anim("confirm", true)
		
		if Input.is_action_just_pressed("ui_cancel"):
			Settings.keybinds = temp_keybinds
			on_leave.call()
			queue_free()
	
	else:
		var prevent: bool = false
		for i: Key in forbidden_keycodes:
			if e.keycode == i:
				prevent = true
				break
		
		if not prevent:
			temp_keybinds[player][note] = OS.get_keycode_string(e.keycode)
		field.receptors.get_child(note).play_anim("static", true)
		binding = false
		update_text()

func update_selected_note(new_note: int = 0):
	if new_note != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	note = wrapi(note + new_note, 0, field.receptors.get_child_count())
	
	for receptor: Receptor in field.receptors.get_children():
		var i: int = receptor.get_index()
		receptor.modulate.v = 0.6 if i != note else 1.0

func update_selected_player(new_player: int = 0):
	if new_player != 0: SoundBoard.play_sfx(Menu2D.SCROLL_SOUND)
	player = wrapi(player + new_player, 0, temp_keybinds.size())
	update_text()

func update_text():
	var base: String = instructions + "\n"
	for i: int in temp_keybinds.size():
		var keybinds: Array = temp_keybinds[i]
		var begin: String = "\n> " if i == player else "\n"
		base += begin + "P%s Binds: %s" % [ i+1, str(keybinds).replace('"', "")]
	$label.text = base
