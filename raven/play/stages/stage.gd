class_name StageBG extends Node2D
const DEFAULT_STAGE: String = "main_stage"

@export var camera_zoom: Vector2 = Vector2(1.05, 1.05)
@export var hud_zoom: Vector2 = Vector2(1.0, 1.0)
@export var camera_speed: float = 1.0
@export var position_markers: PackedVector2Array = [
	Vector2(600, 300), # Player 1
	Vector2(350, 300), # Player 2
	Vector2(650, 300)  # Player 3
]

func _ready() -> void:
	for i: int in position_markers.size():
		var player_name: String = "player%s" % str(i+1)
		if has_node(player_name) and get_node(player_name) is Marker2D:
			position_markers[i] = get_node(player_name).position
