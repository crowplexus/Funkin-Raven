extends Node2D

var _pfo: float = 0.0
var chart: Chart

func _ready() -> void:
	chart = Chart.load_default() if not Chart.global else Chart.global

	# move performance counter away
	_pfo = PerformanceCounter.offset.x
	PerformanceCounter.offset.x = get_viewport_rect().size.x * 0.9

func _exit_tree() -> void:
	PerformanceCounter.offset.y = _pfo

func _process(delta: float) -> void:
	pass
