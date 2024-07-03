extends OptionItem

var _key_index: int = 0


func _ready() -> void:
	check_value()


func update(_amount: int=0) -> void:
	#print_debug(amount)
	pass


func check_value() -> void:
	value = Preferences.keybinds[variable][_key_index]
	reset_preference_label()


func _unhandled_key_input(e: InputEvent) -> void:
	reset_preference_label()
	if is_selected():
		preference_label.text += " (TAB)"
	if variable.is_empty() or not variable in Preferences.keybinds:
		return
	if not is_selected() or not e.is_pressed():
		return

	match e.keycode:
		KEY_TAB when Preferences.keybinds[variable].size() > 1:
			_key_index = wrapi(_key_index + 1, 0, Preferences.keybinds[variable].size())
			check_value()
			preference_label.text += " (TAB)"
			#print_debug(_key_index)

		_ when e.keycode != KEY_ESCAPE:
			if e.keycode == KEY_BACKSPACE:
				$"../../../".stop_changing_pref()
				return
			Preferences.keybinds[variable][_key_index] = OS.get_keycode_string(e.keycode)
			await get_tree().create_timer(0.01).timeout
			window.stop_changing_pref()
			check_value()


func is_selected() -> bool:
	return window.selected_pref == self and window.changing_preference
