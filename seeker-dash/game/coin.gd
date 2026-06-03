extends Area2D

signal collected

var taken := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var tween := create_tween().set_loops()
	tween.tween_property($Sprite, "position:y", -12.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite, "position:y", -8.0, 0.35).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node) -> void:
	if taken:
		return
	if body.is_in_group("player"):
		taken = true
		emit_signal("collected")
		var tween := create_tween()
		tween.tween_property($Sprite, "scale", Vector2(1.6, 1.6), 0.12)
		tween.parallel().tween_property($Sprite, "modulate:a", 0.0, 0.12)
		tween.tween_callback(queue_free)
