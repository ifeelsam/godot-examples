extends CharacterBody2D

signal died
signal stomped_enemy

const GRAVITY := 1200.0
const RUN_SPEED := 240.0
const JUMP_VELOCITY := -460.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.12
const STOMP_BOUNCE := -320.0

var move_dir := 0.0
var jump_pressed := false
var alive := true
var coyote := 0.0
var jump_buffer := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var stomp_zone: Area2D = $StompZone


func _ready() -> void:
	stomp_zone.body_entered.connect(_on_stomp_body_entered)


func _physics_process(delta: float) -> void:
	if not alive:
		return

	if not is_on_floor():
		coyote -= delta
	else:
		coyote = COYOTE_TIME

	if jump_pressed:
		jump_buffer = JUMP_BUFFER
	else:
		jump_buffer = max(0.0, jump_buffer - delta)

	velocity.y += GRAVITY * delta
	velocity.x = move_dir * RUN_SPEED

	if jump_buffer > 0.0 and coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote = 0.0

	move_and_slide()

	if global_position.y > 900.0:
		_kill()


func set_input(direction: float, wants_jump: bool) -> void:
	move_dir = direction
	jump_pressed = wants_jump

	if direction < 0.0:
		sprite.flip_h = true
	elif direction > 0.0:
		sprite.flip_h = false


func _on_stomp_body_entered(body: Node) -> void:
	if not alive or velocity.y <= 0.0:
		return
	if body.is_in_group("enemy") and body.has_method("defeat"):
		body.defeat()
		velocity.y = STOMP_BOUNCE
		emit_signal("stomped_enemy")


func take_damage() -> void:
	if not alive:
		return
	_kill()


func _kill() -> void:
	if not alive:
		return
	alive = false
	velocity = Vector2.ZERO
	sprite.modulate = Color(0.4, 0.4, 0.4)
	emit_signal("died")
