extends Node2D
class_name StageBG

@export var camera: Camera2D
@export var camera_beat_interval: int = 4

var initial_camera_zoom: Vector2 = Vector2.ONE
var current_camera_zoom: Vector2 = Vector2.ONE


func _ready() -> void:
	if camera:
		current_camera_zoom = camera.zoom
		initial_camera_zoom = camera.zoom
		Conductor.ibeat_reached.connect(on_ibeat_reached)


func _process(delta: float) -> void:
	# reset camera zooming #
	if camera and camera.zoom != current_camera_zoom:
		camera.zoom = Vector2(
			lerpf(current_camera_zoom.x, camera.zoom.x, exp(-delta * 5)),
			lerpf(current_camera_zoom.y, camera.zoom.y, exp(-delta * 5))
		)


func _exit_tree() -> void:
	if Conductor.ibeat_reached.is_connected(on_ibeat_reached):
		Conductor.ibeat_reached.disconnect(on_ibeat_reached)


func on_ibeat_reached(ibeat: int) -> void:
	if ibeat % camera_beat_interval == 0:
		camera.zoom += Vector2(0.015, 0.015)


func reset_camera_zoom() -> void:
	current_camera_zoom = initial_camera_zoom
