extends CharacterBody2D

const GRAVITY := 1200.0
const PATROL_SPEED := 70.0

var patrol_left := 0.0
var patrol_right := 0.0
var direction := -1.0
var alive := true

@onready var sprite: ColorRect = $Sprite


func setup(left_x: float, right_x: float, start_right: bool = false) -> void:
	patrol_left = left_x
	patrol_right = right_x
	direction = 1.0 if start_right else -1.0


func _physics_process(delta: float) -> void:
	if not alive:
		return

	velocity.y += GRAVITY * delta
	velocity.x = direction * PATROL_SPEED
	move_and_slide()

	if is_on_wall():
		direction *= -1.0

	if global_position.x <= patrol_left:
		direction = 1.0
	elif global_position.x >= patrol_right:
		direction = -1.0

	sprite.scale.x = direction


func defeat() -> void:
	if not alive:
		return
	alive = false
	collision_layer = 0
	collision_mask = 0
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)

