extends CanvasLayer

enum TransitionType {
	GLOBE		= 0,
	FADE		= 1,
}

@onready var rect: ColorRect = $rect
@export var trans_in_type: = TransitionType.GLOBE
@export var trans_out_type: = TransitionType.GLOBE

var twn: Tween

func _ready() -> void:
	var shdr: ShaderMaterial = rect.material as ShaderMaterial
	shdr.set_shader_parameter("screen_width", rect.size.x)
	shdr.set_shader_parameter("screen_height", rect.size.y)

func transition_in() -> void:
	if twn != null: twn.kill()
	twn = create_tween().bind_node(rect)
	twn.set_ease(Tween.EASE_IN)
	match trans_in_type:
		TransitionType.GLOBE:
			rect.position.y = 0
			twn.tween_method(set_circ_size, get_circ_size(), 0.0, 0.35)
		_:
			rect.position.y = 0
			set_circ_size(0.0)
			twn.tween_property(rect, "color:a", 1.0, 0.35)
	await twn.finished

func transition_out() -> void:
	if twn != null: twn.kill()
	twn = create_tween().bind_node(rect)
	twn.set_ease(Tween.EASE_OUT)

	match trans_in_type:
		TransitionType.GLOBE:
			rect.position.y = 0
			twn.tween_method(set_circ_size, get_circ_size(), 1.05, 0.35)
		_:
			rect.position.y = 0
			set_circ_size(0.0)
			twn.tween_property(rect, "color:a", 0.0, 0.35)
	await twn.finished

# for globe transition #

func get_circ_size() -> float:
	var shdr: ShaderMaterial = (rect.material as ShaderMaterial)
	return shdr.get_shader_parameter("circle_size")

func set_circ_size(size: float) -> void:
	var shdr: ShaderMaterial = (rect.material as ShaderMaterial)
	shdr.set_shader_parameter("circle_size", size)
