extends Control

@onready var health_bar: = $"health_bar"
var hb_twn: Tween

func _ready() -> void:
	health_bar.modulate.a = 0.0
	hb_twn = create_tween().set_ease(Tween.EASE_IN).bind_node(health_bar)
	hb_twn.tween_property(health_bar, "modulate:a", 1.0, 1.5 * Conductor.crotchet)
