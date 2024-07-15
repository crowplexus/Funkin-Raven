@tool extends OptionItem


func reset_preference_label() -> void:
	if preference_label:
		var final_text: String = option_name
		preference_label.text = final_text


func _on_mouse_entered() -> void:
	if not window:
		return
	modulate.a = 0.8


func _on_mouse_exited() -> void:
	if not window:
		return
	modulate.a = 1.0 if name == window.active_page.name else 0.6


func _on_gui_input(e: InputEvent) -> void:
	if e.is_released() or not window:
		return
	if e.is_action("ui_accept") and not window.changing_preference:
		window.update_page(0, self.get_index())
