extends CharacterBody2D

const GRAVITY := 1400.0

var patrol_left := 0.0
var patrol_right := 0.0
var direction := -1.0
var speed := 80.0
var alive := true
var flying := false
var bob_amp := 0.0
var bob_speed := 3.0
var base_y := 0.0
var bob_t := 0.0
var sound_key := ""

@onready var sprite: AnimatedSprite2D = $Sprite


func setup(left_x: float, right_x: float, start_right: bool = false, opts: Dictionary = {}) -> void:
	patrol_left = left_x
	patrol_right = right_x
	direction = 1.0 if start_right else -1.0
	speed = float(opts.get("speed", speed))
	flying = bool(opts.get("flying", false))
	bob_amp = float(opts.get("bob", 0.0))
	bob_speed = float(opts.get("bob_speed", 3.0))
	sound_key = String(opts.get("sound", ""))
	base_y = global_position.y


func _physics_process(delta: float) -> void:
	if not alive:
		return

	if flying:
		position.x += direction * speed * delta
		if global_position.x <= patrol_left:
			direction = 1.0
		elif global_position.x >= patrol_right:
			direction = -1.0
		if bob_amp > 0.0:
			bob_t += delta
			position.y = base_y + sin(bob_t * bob_speed) * bob_amp
	else:
		velocity.y += GRAVITY * delta
		velocity.x = direction * speed
		move_and_slide()
		if is_on_wall():
			direction *= -1.0
		if global_position.x <= patrol_left:
			direction = 1.0
		elif global_position.x >= patrol_right:
			direction = -1.0

	sprite.flip_h = direction < 0.0


func defeat() -> void:
	if not alive:
		return
	alive = false
	collision_layer = 0
	collision_mask = 0
	if sound_key != "":
		Sfx.play(sound_key, -3.0)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * Vector2(1.2, 0.4), 0.1)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
