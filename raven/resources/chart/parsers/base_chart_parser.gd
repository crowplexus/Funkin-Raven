class_name ChartParser extends RefCounted

var data: Dictionary = {}

func _init(new_data: Dictionary):
	self.data = new_data

func parse() -> Chart:
	# implement parsing method here.
	return Chart.new()
