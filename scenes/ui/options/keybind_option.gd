extends OptionItem


func _ready() -> void:
	check_value()


func update(amount: int=0) -> void:
	print_debug(amount)


func check_value() -> void:
	value = Preferences.keybinds[variable][0]
	reset_preference_label()


func _unhandled_key_input(e: InputEvent) -> void:
	if not is_selected() or not e.is_pressed():
		return

	match e.keycode:
		_ when e.keycode != KEY_ESCAPE:
			if e.keycode == KEY_BACKSPACE:
				$"../../../".stop_changing_pref()
				return

			var key: int = e.keycode
			Preferences.keybinds[variable][0] = OS.get_keycode_string(key)
			window.stop_changing_pref()
			check_value()


func is_selected() -> bool:
	return window.changing_preference and window.selected_pref == self
