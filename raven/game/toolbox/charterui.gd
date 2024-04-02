extends Control

@onready var file_bttn: MenuButton = $menu_bar/file

func _ready():
	file_bttn.get_popup().id_pressed.connect(_on_file_menu_pressed)

func _unhandled_key_input(e: InputEvent):
	if e.pressed: match e.keycode:
		KEY_F1: $help_stuff/help_screen.visible = not $help_stuff/help_screen.visible
		KEY_B: file_bttn.show_popup()

func _on_file_menu_pressed(id: int):
	print_debug("test%s"%id)
