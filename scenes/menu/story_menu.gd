extends Node2D


var _pfo: float = 0.0
func _ready() -> void:
	_pfo = PerformanceCounter.offset.y
	PerformanceCounter.offset.y = $"level_clear".position.y


func _exit_tree() -> void:
	PerformanceCounter.offset.y = _pfo


func _unhandled_input(e: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Globals.change_scene(load("res://scenes/menu/main_menu.tscn"))
