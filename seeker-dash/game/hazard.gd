extends Area2D

# Instant-death trap (spikes, saws, flames, swinging axe). Touching it kills the
# player, exactly like classic platformer hazards.

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
