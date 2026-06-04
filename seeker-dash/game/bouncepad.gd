extends Area2D

# Trampoline spring. When the player drops onto it they launch high, with a quick
# squash-and-stretch animation and a boing sound.

@export var strength := -900.0

var anim: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)


func bind_anim(a: AnimatedSprite2D) -> void:
	anim = a
	anim.stop()
	anim.frame = 0
	anim.animation_finished.connect(func() -> void: anim.frame = 0)


func _on_body_entered(body: Node) -> void:
	if not (body.is_in_group("player") and body.has_method("bounce")):
		return
	if body.velocity.y < -20.0:
		return
	body.bounce(strength)
	if anim != null:
		anim.frame = 0
		anim.play("default")
