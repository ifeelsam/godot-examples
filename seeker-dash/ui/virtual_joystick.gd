extends Control

signal direction_changed(direction: Vector2)

@export var joystick_radius := 68.0
@export var knob_radius := 26.0
@export var deadzone := 0.16

var _direction := Vector2.ZERO
var _dragging := false
var _pointer_id := -1
var _base: PanelContainer
var _knob: PanelContainer


func _ready() -> void:
	custom_minimum_size = Vector2(joystick_radius * 2.0 + 32.0, joystick_radius * 2.0 + 32.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_base = PanelContainer.new()
	_base.name = "Base"
	_base.position = Vector2(16, 16)
	_style_disc(_base, joystick_radius, Color(0.12, 0.16, 0.24, 0.82), Color(0.35, 0.55, 0.85, 0.35))
	add_child(_base)

	_knob = PanelContainer.new()
	_knob.name = "Knob"
	_style_disc(_knob, knob_radius, Color(0.28, 0.62, 0.95, 0.95), Color(0.55, 0.82, 1.0, 0.55))
	_base.add_child(_knob)

	_reset_knob()


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
		if local_pos.distance_to(_base_center()) > joystick_radius + 20.0:
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
	var center := _base_center()
	var offset := local_pos - center
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius

	var knob_center := Vector2(joystick_radius, joystick_radius) + offset
	_knob.position = knob_center - Vector2(knob_radius, knob_radius)

	var normalized := offset / joystick_radius
	if normalized.length() < deadzone:
		_set_direction(Vector2.ZERO)
	else:
		_set_direction(normalized)


func _stop_drag() -> void:
	_dragging = false
	_pointer_id = -1
	_reset_knob()
	_set_direction(Vector2.ZERO)


func _reset_knob() -> void:
	_knob.position = Vector2(joystick_radius - knob_radius, joystick_radius - knob_radius)


func _base_center() -> Vector2:
	return _base.position + Vector2(joystick_radius, joystick_radius)


func _set_direction(value: Vector2) -> void:
	if _direction.is_equal_approx(value):
		return
	_direction = value
	emit_signal("direction_changed", _direction)


func _style_disc(panel: PanelContainer, radius: float, fill: Color, border: Color) -> void:
	panel.custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(radius))
	panel.add_theme_stylebox_override("panel", style)
