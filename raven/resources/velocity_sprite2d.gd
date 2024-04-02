class_name VelocitySprite2D
extends Sprite2D

@export var moving: bool:
	get: return (velocity.x != 0 or velocity.y != 0
				or acceleration.x != 0 or acceleration.y != 0)

var acceleration: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

func _process(delta: float):
	if moving: _process_velocity(delta)

func _process_velocity(delta: float):
	# copying haxeflixel formula for sprites that use that
	var velocity_delta: Vector2 = VelocitySprite2D._get_velocity_delta(velocity, acceleration, delta)
	
	position.x += (velocity.x + velocity_delta.x) * delta
	position.y += (velocity.y + velocity_delta.y) * delta
	
	velocity.x += velocity_delta.x * 2.0
	velocity.y += velocity_delta.y * 2.0

static func _compute_velocity(vel: float, accel: float, delta: float) -> float:
	return vel + (accel * delta if accel != 0.0 else 0.0)

static func _get_velocity_delta(vel: Vector2, accel: Vector2, delta: float) -> Vector2:
	return Vector2(
		0.5 * (_compute_velocity(vel.x, accel.x, delta) - vel.x),
		0.5 * (_compute_velocity(vel.y, accel.y, delta) - vel.y),
	)
