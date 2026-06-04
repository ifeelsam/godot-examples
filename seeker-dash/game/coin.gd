extends Area2D

# Generic collectible. kind "coin" feeds the coin counter; kind "star" feeds the
# bonus star counter. Both share the bob animation and pickup pop.

signal collected(kind: String, value: int)

@export var kind := "coin"
@export var value := 1

var taken := false
var _base_scale := Vector2.ONE


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var s: Sprite2D = $Sprite
	_base_scale = s.scale

	var bob := create_tween().set_loops()
	bob.tween_property(s, "position:y", -14.0, 0.45).set_trans(Tween.TRANS_SINE)
	bob.tween_property(s, "position:y", -4.0, 0.45).set_trans(Tween.TRANS_SINE)

	if kind == "coin":
		var spin := create_tween().set_loops()
		spin.tween_property(s, "scale:x", _base_scale.x * 0.25, 0.4).set_trans(Tween.TRANS_SINE)
		spin.tween_property(s, "scale:x", _base_scale.x, 0.4).set_trans(Tween.TRANS_SINE)
	else:
		var pulse := create_tween().set_loops()
		pulse.tween_property(s, "scale", _base_scale * 1.12, 0.5).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(s, "scale", _base_scale, 0.5).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node) -> void:
	if taken:
		return
	if body.is_in_group("player"):
		taken = true
		emit_signal("collected", kind, value)
		Sfx.play("coin", 0.0, 1.0 if kind == "coin" else 1.5)
		var s: Sprite2D = $Sprite
		var tween := create_tween()
		tween.tween_property(s, "scale", _base_scale * 1.7, 0.12)
		tween.parallel().tween_property(s, "modulate:a", 0.0, 0.12)
		tween.tween_callback(queue_free)
