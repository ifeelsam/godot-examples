extends Control

signal connect_pressed
signal skip_pressed

enum State { IDLE, CONNECTING, CONNECTED, ERROR }

const PIXEL := preload("res://game/pixel_assets.gd")

var _panel: PanelContainer
var _title_label: Label
var _body_label: Label
var _address_label: Label
var _status_label: Label
var _connect_button: Button
var _skip_button: Button
var _state := State.IDLE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.1, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.11, 0.14, 0.24, 0.98)
	panel_style.border_color = Color(0.55, 0.75, 0.35, 0.85)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(4)
	panel_style.shadow_color = Color(0, 0, 0, 0.45)
	panel_style.shadow_size = 12
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	_panel.add_theme_stylebox_override("panel", panel_style)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	_panel.add_child(stack)

	var logo := TextureRect.new()
	logo.texture = PIXEL.TEX_LOGO
	logo.custom_minimum_size = Vector2(0, 168)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stack.add_child(logo)

	var hero := HBoxContainer.new()
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_theme_constant_override("separation", 12)
	stack.add_child(hero)

	var player_icon := TextureRect.new()
	player_icon.texture = PIXEL.player_icon()
	player_icon.custom_minimum_size = Vector2(48, 48)
	player_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hero.add_child(player_icon)

	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 2)
	hero.add_child(title_col)

	var badge := Label.new()
	badge.text = "SOLANA MOBILE"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color(0.55, 0.9, 0.45))
	title_col.add_child(badge)

	_title_label = Label.new()
	_title_label.text = "SEEKER DASH"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.36))
	title_col.add_child(_title_label)

	_body_label = Label.new()
	_body_label.text = "Connect your wallet to sign checkpoint proofs and a level-clear receipt as you play."
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.95))
	stack.add_child(_body_label)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color(0.35, 0.45, 0.65, 0.35)
	stack.add_child(divider)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
	stack.add_child(_status_label)

	_address_label = Label.new()
	_address_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_address_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_address_label.add_theme_font_size_override("font_size", 12)
	_address_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.75))
	stack.add_child(_address_label)

	_connect_button = _make_button("Connect Wallet", Color(0.28, 0.58, 0.32))
	_connect_button.pressed.connect(func():
		Sfx.play("confirm")
		emit_signal("connect_pressed"))
	stack.add_child(_connect_button)

	_skip_button = _make_button("Play without wallet", Color(0.22, 0.26, 0.34))
	_skip_button.pressed.connect(func():
		Sfx.play("confirm")
		emit_signal("skip_pressed"))
	stack.add_child(_skip_button)

	set_state(State.IDLE)


func set_bridge_available(available: bool) -> void:
	_skip_button.visible = not available
	if not available:
		_body_label.text = "Wallet bridge unavailable on desktop. Play without a wallet, or export to Android / Seeker to connect."
	else:
		_body_label.text = "Connect your wallet to sign checkpoint proofs and a level-clear receipt as you play."


func set_state(state: State, detail: String = "") -> void:
	_state = state
	match state:
		State.IDLE:
			_status_label.text = "Sign in to start your run"
			_address_label.text = ""
			_connect_button.disabled = false
			_connect_button.text = "Connect Wallet"
			_skip_button.disabled = false
		State.CONNECTING:
			_status_label.text = "Opening wallet..."
			_address_label.text = ""
			_connect_button.disabled = true
			_connect_button.text = "Connecting..."
			_skip_button.disabled = true
		State.CONNECTED:
			_status_label.text = "Wallet connected"
			_address_label.text = detail
			_connect_button.disabled = true
			_connect_button.text = "Starting..."
			_skip_button.disabled = true
		State.ERROR:
			_status_label.text = detail if not detail.is_empty() else "Connection failed"
			_address_label.text = ""
			_connect_button.disabled = false
			_connect_button.text = "Try again"
			_skip_button.disabled = false


func show_gate() -> void:
	visible = true
	if _state != State.CONNECTING:
		set_state(State.IDLE)


func hide_gate() -> void:
	visible = false


func _make_button(text: String, fill: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.focus_mode = Control.FOCUS_NONE

	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = fill.darkened(0.25)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	normal.shadow_color = Color(0.05, 0.15, 0.05, 0.35)
	normal.shadow_size = 4
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = fill.lightened(0.08)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = fill.darkened(0.08)
	button.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate()
	disabled.bg_color = fill.darkened(0.2)
	button.add_theme_stylebox_override("disabled", disabled)

	return button
