extends Node2D

var _pfo: float = 0.0
func _ready() -> void:
	if not SoundBoard.is_bgm_playing():
		SoundBoard.play_bgm(Globals.MENU_MUSIC, 0.7)
	_pfo = PerformanceCounter.offset.y
	PerformanceCounter.offset.y = $"level_clear".position.y

func _exit_tree() -> void:
	PerformanceCounter.offset.y = _pfo

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		Globals.change_scene(load("res://scenes/menu/main_menu.tscn"))
