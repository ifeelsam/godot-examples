extends Control

signal direction_changed(direction: Vector2)

const PAD_TEXTURE := preload("res://ui/mobile-controls/Vector/Style A/joystick_circle_pad_a.svg")
const NUB_TEXTURE := preload("res://ui/mobile-controls/Vector/Style A/joystick_circle_nub_a.svg")

@export var pad_size := 128.0
@export var nub_size := 56.0
@export var deadzone := 0.16

var _direction := Vector2.ZERO
var _dragging := false
var _pointer_id := -1
var _pad: TextureRect
var _nub: TextureRect


func _ready() -> void:
	custom_minimum_size = Vector2(pad_size + 32.0, pad_size + 32.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_pad = _make_sprite(PAD_TEXTURE, pad_size)
	_pad.name = "Pad"
	_pad.position = Vector2(16, 16)
	add_child(_pad)

	_nub = _make_sprite(NUB_TEXTURE, nub_size)
	_nub.name = "Nub"
	_pad.add_child(_nub)

	_reset_nub()


func get_direction() -> Vector2:
	return _direction


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_press(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_press(0, event.position, event.pressed)
	elif event is InputEventMouseMotion and _dragging and _pointer_id == 0:
		_handle_drag(0, event.position)


func _handle_press(pointer_id: int, local_pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _dragging:
			return
		if local_pos.distance_to(_pad_center()) > pad_size * 0.5 + 20.0:
			return
		_dragging = true
		_pointer_id = pointer_id
		_update_direction(local_pos)
	else:
		if not _dragging or pointer_id != _pointer_id:
			return
		_stop_drag()


func _handle_drag(pointer_id: int, local_pos: Vector2) -> void:
	if not _dragging or pointer_id != _pointer_id:
		return
	_update_direction(local_pos)


func _update_direction(local_pos: Vector2) -> void:
	var center := _pad_center()
	var offset := local_pos - center
	var max_radius := pad_size * 0.5
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius

	var nub_center := Vector2(pad_size * 0.5, pad_size * 0.5) + offset
	_nub.position = nub_center - Vector2(nub_size * 0.5, nub_size * 0.5)

	var normalized := offset / max_radius
	if normalized.length() < deadzone:
		_set_direction(Vector2.ZERO)
	else:
		_set_direction(normalized)


func _stop_drag() -> void:
	_dragging = false
	_pointer_id = -1
	_reset_nub()
	_set_direction(Vector2.ZERO)


func _reset_nub() -> void:
	_nub.position = Vector2(
		pad_size * 0.5 - nub_size * 0.5,
		pad_size * 0.5 - nub_size * 0.5
	)


func _pad_center() -> Vector2:
	return _pad.position + Vector2(pad_size * 0.5, pad_size * 0.5)


func _set_direction(value: Vector2) -> void:
	if _direction.is_equal_approx(value):
		return
	_direction = value
	emit_signal("direction_changed", _direction)


func _make_sprite(texture: Texture2D, size: float) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.custom_minimum_size = Vector2(size, size)
	sprite.size = Vector2(size, size)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sprite
