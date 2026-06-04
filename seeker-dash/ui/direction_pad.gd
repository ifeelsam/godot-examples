extends Control

signal direction_changed(direction: float)

const LEFT_TEXTURE := preload("res://ui/mobile-controls/Vector/Style A/direction_left.svg")
const RIGHT_TEXTURE := preload("res://ui/mobile-controls/Vector/Style A/direction_right.svg")

@export var button_size := 96.0

var _left_held := false
var _right_held := false
var _direction := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(button_size * 2.0 + 12.0, button_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(row)

	var left := _make_button(LEFT_TEXTURE)
	left.pressed_changed.connect(func(held: bool): _set_left(held))
	row.add_child(left)

	var right := _make_button(RIGHT_TEXTURE)
	right.pressed_changed.connect(func(held: bool): _set_right(held))
	row.add_child(right)


func _set_left(held: bool) -> void:
	_left_held = held
	_update_direction()


func _set_right(held: bool) -> void:
	_right_held = held
	_update_direction()


func _update_direction() -> void:
	var value := 0.0
	if _left_held and not _right_held:
		value = -1.0
	elif _right_held and not _left_held:
		value = 1.0

	if is_equal_approx(_direction, value):
		return
	_direction = value
	emit_signal("direction_changed", _direction)


func _make_button(texture: Texture2D) -> TouchTextureButton:
	var button := TouchTextureButton.new()
	button.normal_texture = texture
	button.button_size = button_size
	return button
