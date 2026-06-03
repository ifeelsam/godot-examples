extends Area2D

signal reached

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if body.is_in_group("player"):
		triggered = true
		emit_signal("reached")
