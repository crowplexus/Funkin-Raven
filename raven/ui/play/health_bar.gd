extends ProgressBar
# just a helper script for minor stuff
var left_color: Color = Color.RED:
	set(v): get_theme_stylebox("background").bg_color = v
var right_color: Color = Color("#55ff00"):
	set(v): get_theme_stylebox("fill").bg_color = v

func set_colors(left: Color = Color.RED, right: Color = Color("#55ff00")) -> void:
	left_color = left
	right_color = right
