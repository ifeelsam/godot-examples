extends Control

signal pressed_changed(pressed: bool)

@export var normal_texture: Texture2D
@export var button_size := 96.0

var pressed := false

var _active_pointers := {}


func _ready() -> void:
	custom_minimum_size = Vector2(button_size, button_size)
	size = Vector2(button_size, button_size)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	var icon := TextureRect.new()
	icon.texture = normal_texture
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	move_child(icon, 0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch(0, event.position, event.pressed)


func _handle_touch(pointer_id: int, global_pos: Vector2, is_pressed: bool) -> void:
	if is_pressed:
		if not _contains_global_point(global_pos):
			return
		_active_pointers[pointer_id] = true
		_set_pressed(true)
		accept_event()
	elif _active_pointers.has(pointer_id):
		_active_pointers.erase(pointer_id)
		_set_pressed(not _active_pointers.is_empty())
		accept_event()


func _contains_global_point(global_pos: Vector2) -> bool:
	return get_global_rect().has_point(global_pos)


func _set_pressed(value: bool) -> void:
	if pressed == value:
		return
	pressed = value
	modulate = Color(0.82, 0.82, 0.82, 1.0) if pressed else Color(1, 1, 1, 1)
	emit_signal("pressed_changed", pressed)
