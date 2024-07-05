extends GDScript
func _on_pause(scene: Node,_e: InputEvent) -> int:
	var pause_menu: Control = load("res://scenes/ui/pause/pause_menu_pixel.tscn").instantiate()
	pause_menu.z_index = 100
	scene.get_tree().paused = true
	scene.ui_layer.add_child(pause_menu)
	return ModchartPack.CallableRequest.STOP
