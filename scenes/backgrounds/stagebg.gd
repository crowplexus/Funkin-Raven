extends Node2D
class_name StageBG

@export var camera: Camera2D
@export var camera_beat_interval: int = 4
var initial_camera_zoom: Vector2 = Vector2.ONE

func _ready() -> void:
	if is_instance_valid(camera):
		initial_camera_zoom = camera.zoom
		Conductor.beat_reached.connect(on_beat_reached)


func _process(delta: float) -> void:
	# reset camera zooming #
	if is_instance_valid(camera) and camera.zoom != initial_camera_zoom:
		camera.zoom = Vector2(
			lerpf(initial_camera_zoom.x, camera.zoom.x, exp(-delta * 5)),
			lerpf(initial_camera_zoom.y, camera.zoom.y, exp(-delta * 5))
		)


func _exit_tree() -> void:
	if Conductor.beat_reached.is_connected(on_beat_reached):
		Conductor.beat_reached.disconnect(on_beat_reached)


func on_beat_reached(beat: int) -> void:
	if beat % camera_beat_interval == 0:
		camera.zoom += Vector2(0.015, 0.015)
