extends Control

# Seeker Dash — a side-scrolling platformer inspired by classic Mario runners.
# Landscape layout with a wallet gate dialog; connecting auto-starts the run.

const WORLD_SCRIPT := preload("res://game/platform_world.gd")
const WALLET_GATE_SCRIPT := preload("res://ui/wallet_gate.gd")
const VIRTUAL_JOYSTICK_SCRIPT := preload("res://ui/virtual_joystick.gd")
const JUMP_BUTTON_TEXTURE := preload("res://ui/mobile-controls/Vector/Style A/button_circle.svg")
const JUMP_ICON_TEXTURE := preload("res://ui/mobile-controls/Vector/Icons/icon_jump.svg")
const SAVE_PATH := "user://seeker_dash.save"
const CHECKPOINT_COINS := 5

const COLOR_BG := Color(0.05, 0.07, 0.12)
const COLOR_HUD := Color(0.08, 0.1, 0.16, 0.88)
const COLOR_ACCENT := Color(0.35, 0.78, 0.95)
const COLOR_GOLD := Color(0.95, 0.82, 0.35)

var wallet_adapter: WalletAdapter

var wallet_gate: Control
var game_root: Control
var hud_bar: PanelContainer
var hud_label: Label
var best_label: Label
var wallet_chip: Label
var disconnect_button: Button
var results_panel: PanelContainer
var results_label: Label
var play_again_button: Button
var viewport_container: SubViewportContainer
var sub_viewport: SubViewport
var world: Node2D
var touch_controls: Control
var virtual_joystick: Control
var jump_button: TextureButton
var toast_label: Label

var playing := false
var awaiting_sign := false
var touch_direction := 0.0
var jump_held := false
var last_checkpoint := 0
var best_time := 9999.0
var best_coins := 0
var pending_auto_start := false


func _ready() -> void:
	randomize()
	_load_best()
	_build_ui()
	_setup_world()
	_setup_wallet()
	_refresh_hud()
	_show_wallet_gate()


func _process(_delta: float) -> void:
	if world == null:
		return

	var direction := touch_direction
	if absf(direction) < 0.05:
		direction = Input.get_axis("move_left", "move_right")

	var wants_jump := jump_held or Input.is_action_pressed("jump")
	world.set_controls(direction, wants_jump)

	if playing:
		_refresh_hud()


func _setup_world() -> void:
	world = Node2D.new()
	world.set_script(WORLD_SCRIPT)
	sub_viewport.add_child(world)

	world.coin_collected.connect(_on_coin_collected)
	world.enemy_stomped.connect(_on_enemy_stomped)
	world.player_died.connect(_on_player_died)
	world.level_finished.connect(_on_level_finished)


func _setup_wallet() -> void:
	wallet_adapter = WalletAdapter.new()
	wallet_adapter.identity_name = "Seeker Dash"
	wallet_adapter.identity_uri = "https://seeker.arcade"
	wallet_adapter.icon_uri = "favicon.ico"
	wallet_adapter.cluster = WalletAdapter.Cluster.DEVNET
	add_child(wallet_adapter)

	wallet_adapter.connection_established.connect(_on_connected)
	wallet_adapter.connection_failed.connect(_on_connection_failed)
	wallet_adapter.message_signed.connect(_on_message_signed)
	wallet_adapter.sign_failed.connect(_on_sign_failed)
	wallet_adapter.disconnected.connect(_on_disconnected)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	game_root = Control.new()
	game_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(game_root)

	viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	game_root.add_child(viewport_container)

	sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2(960, 540)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.handle_input_locally = false
	viewport_container.add_child(sub_viewport)

	hud_bar = _make_hud_bar()
	game_root.add_child(hud_bar)

	var stats_box: VBoxContainer = hud_bar.get_meta("stats_box")
	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 17)
	stats_box.add_child(hud_label)

	best_label = Label.new()
	best_label.add_theme_font_size_override("font_size", 14)
	best_label.add_theme_color_override("font_color", COLOR_GOLD)
	stats_box.add_child(best_label)

	var wallet_box: HBoxContainer = hud_bar.get_meta("wallet_box")

	wallet_chip = Label.new()
	wallet_chip.add_theme_font_size_override("font_size", 13)
	wallet_chip.add_theme_color_override("font_color", COLOR_ACCENT)
	wallet_box.add_child(wallet_chip)

	disconnect_button = Button.new()
	disconnect_button.text = "Disconnect"
	disconnect_button.focus_mode = Control.FOCUS_NONE
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	wallet_box.add_child(disconnect_button)

	touch_controls = Control.new()
	touch_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_root.add_child(touch_controls)

	virtual_joystick = Control.new()
	virtual_joystick.set_script(VIRTUAL_JOYSTICK_SCRIPT)
	virtual_joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	virtual_joystick.offset_left = 12
	virtual_joystick.offset_top = -160
	virtual_joystick.offset_right = 160
	virtual_joystick.offset_bottom = -12
	virtual_joystick.direction_changed.connect(_on_joystick_direction)
	touch_controls.add_child(virtual_joystick)

	jump_button = _make_jump_button()
	jump_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump_button.offset_left = -112
	jump_button.offset_top = -112
	jump_button.offset_right = -16
	jump_button.offset_bottom = -16
	jump_button.button_down.connect(func():
		jump_held = true
		jump_button.modulate = Color(0.82, 0.82, 0.82, 1.0)
	)
	jump_button.button_up.connect(func():
		jump_held = false
		jump_button.modulate = Color(1, 1, 1, 1)
	)
	touch_controls.add_child(jump_button)

	results_panel = _make_results_panel()
	game_root.add_child(results_panel)

	var results_stack: VBoxContainer = results_panel.get_meta("stack")
	results_label = Label.new()
	results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_stack.add_child(results_label)

	play_again_button = _make_touch_button("Play Again")
	play_again_button.custom_minimum_size = Vector2(180, 48)
	play_again_button.pressed.connect(_on_play_again_pressed)
	results_stack.add_child(play_again_button)

	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toast_label.offset_top = -120
	toast_label.offset_bottom = -92
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 13)
	toast_label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	game_root.add_child(toast_label)

	wallet_gate = Control.new()
	wallet_gate.set_script(WALLET_GATE_SCRIPT)
	wallet_gate.set_anchors_preset(Control.PRESET_FULL_RECT)
	wallet_gate.connect_pressed.connect(_on_gate_connect_pressed)
	wallet_gate.skip_pressed.connect(_on_gate_skip_pressed)
	add_child(wallet_gate)

	_set_playing_ui(false)


func _make_hud_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 72

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_HUD
	style.set_corner_radius_all(0)
	style.border_color = Color(0.25, 0.35, 0.55, 0.35)
	style.set_border_width_all(1)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	bar.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	bar.add_child(row)

	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("separation", 2)
	row.add_child(stats)

	var wallet_box := HBoxContainer.new()
	wallet_box.add_theme_constant_override("separation", 8)
	row.add_child(wallet_box)

	bar.set_meta("stats_box", stats)
	bar.set_meta("wallet_box", wallet_box)

	return bar


func _make_results_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.13, 0.22, 0.94)
	style.border_color = COLOR_GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)

	var title := Label.new()
	title.text = "Level Complete"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	stack.add_child(title)

	panel.set_meta("stack", stack)

	return panel


func _make_jump_button() -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(96, 96)
	button.texture_normal = JUMP_BUTTON_TEXTURE
	button.texture_pressed = JUMP_BUTTON_TEXTURE
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.focus_mode = Control.FOCUS_NONE

	var icon := TextureRect.new()
	icon.texture = JUMP_ICON_TEXTURE
	icon.custom_minimum_size = Vector2(42, 42)
	icon.size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -21
	icon.offset_top = -21
	icon.offset_right = 21
	icon.offset_bottom = 21
	button.add_child(icon)

	return button


func _on_joystick_direction(direction: Vector2) -> void:
	touch_direction = direction.x


func _make_touch_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(96, 64)
	button.focus_mode = Control.FOCUS_NONE

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.16, 0.2, 0.3, 0.92)
	normal.set_corner_radius_all(14)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.22, 0.28, 0.4, 0.95)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.12, 0.16, 0.24, 0.95)
	button.add_theme_stylebox_override("pressed", pressed)

	return button


func _show_wallet_gate() -> void:
	pending_auto_start = false
	results_panel.visible = false
	_set_playing_ui(false)
	wallet_gate.set_bridge_available(wallet_adapter.is_available())
	wallet_gate.show_gate()


func _set_playing_ui(active: bool) -> void:
	playing = active
	touch_controls.visible = active
	hud_bar.visible = active
	toast_label.visible = active
	if not active:
		touch_direction = 0.0
		jump_held = false


func _start_run() -> void:
	if playing or awaiting_sign:
		return
	last_checkpoint = 0
	results_panel.visible = false
	wallet_gate.hide_gate()
	_set_playing_ui(true)
	world.start_run()
	_toast("Run started — reach the flag!")


func _on_gate_connect_pressed() -> void:
	if not wallet_adapter.is_available():
		wallet_gate.set_state(wallet_gate.State.ERROR, "Wallet bridge unavailable on desktop.")
		return
	pending_auto_start = true
	wallet_gate.set_state(wallet_gate.State.CONNECTING)
	wallet_adapter.connect_wallet()


func _on_gate_skip_pressed() -> void:
	pending_auto_start = false
	wallet_gate.hide_gate()
	_start_run()


func _on_play_again_pressed() -> void:
	if wallet_adapter.is_wallet_connected():
		_start_run()
	else:
		_show_wallet_gate()


func _on_coin_collected(total: int) -> void:
	if total > 0 and total % CHECKPOINT_COINS == 0 and total != last_checkpoint:
		last_checkpoint = total
		_toast("Checkpoint: %d coins" % total)
		_sign_checkpoint(total)


func _on_enemy_stomped(_total: int) -> void:
	pass


func _on_player_died(deaths: int) -> void:
	_toast("Ouch! Deaths: %d" % deaths)


func _on_level_finished(stats: Dictionary) -> void:
	_set_playing_ui(false)

	var time: float = stats.get("time", 0.0)
	var coin_count: int = stats.get("coins", 0)
	var death_count: int = stats.get("deaths", 0)
	var stomp_count: int = stats.get("stomps", 0)

	var improved := false
	if time < best_time:
		best_time = time
		improved = true
	if coin_count > best_coins:
		best_coins = coin_count
		improved = true
	if improved:
		_save_best()

	results_label.text = "Time %0.1fs\n%d coins  •  %d stomps  •  %d deaths" % [
		time, coin_count, stomp_count, death_count
	]
	results_panel.visible = true
	_sign_level_clear(stats)
	_refresh_hud()


func _sign_checkpoint(coin_total: int) -> void:
	if not wallet_adapter.is_wallet_connected():
		return
	awaiting_sign = true
	_toast("Signing checkpoint...")
	wallet_adapter.sign_message(
		"Seeker Dash checkpoint coins %d deaths %d at %d" % [
			coin_total,
			world.get_hud().get("deaths", 0),
			int(Time.get_unix_time_from_system()),
		]
	)


func _sign_level_clear(stats: Dictionary) -> void:
	if not wallet_adapter.is_wallet_connected():
		_toast("Connect a wallet to sign your level-clear proof.")
		return
	awaiting_sign = true
	_toast("Signing level clear...")
	wallet_adapter.sign_message(
		"Seeker Dash clear time %0.2f coins %d stomps %d deaths %d at %d" % [
			stats.get("time", 0.0),
			stats.get("coins", 0),
			stats.get("stomps", 0),
			stats.get("deaths", 0),
			int(Time.get_unix_time_from_system()),
		]
	)


func _on_disconnect_pressed() -> void:
	wallet_adapter.disconnect_wallet()


func _on_connected(address: String) -> void:
	wallet_gate.set_state(wallet_gate.State.CONNECTED, _short_address(address))
	_refresh_wallet_ui()
	if pending_auto_start:
		await get_tree().create_timer(0.45).timeout
		pending_auto_start = false
		_start_run()


func _on_connection_failed(error: String) -> void:
	pending_auto_start = false
	wallet_gate.set_state(wallet_gate.State.ERROR, error)
	_refresh_wallet_ui()


func _on_message_signed(signature: PackedByteArray) -> void:
	awaiting_sign = false
	_toast("Signed %s..." % signature.hex_encode().substr(0, 16))
	_refresh_wallet_ui()


func _on_sign_failed(error: String) -> void:
	awaiting_sign = false
	_toast("Sign failed: %s" % error)
	_refresh_wallet_ui()


func _on_disconnected() -> void:
	pending_auto_start = false
	_refresh_wallet_ui()
	if not playing:
		wallet_gate.show_gate()
		wallet_gate.set_state(wallet_gate.State.IDLE)


func _refresh_wallet_ui() -> void:
	var connected := wallet_adapter != null and wallet_adapter.is_wallet_connected()
	disconnect_button.visible = connected
	if connected:
		wallet_chip.text = _short_address(wallet_adapter.get_connected_address())
	else:
		wallet_chip.text = "No wallet"


func _refresh_hud() -> void:
	if world == null:
		return
	var hud: Dictionary = world.get_hud()
	hud_label.text = "Coins %d   Stomps %d   Deaths %d   Time %0.1fs" % [
		hud.get("coins", 0),
		hud.get("stomps", 0),
		hud.get("deaths", 0),
		hud.get("time", 0.0),
	]
	if best_time < 9999.0:
		best_label.text = "Best %0.1fs  •  %d coins" % [best_time, best_coins]
	else:
		best_label.text = "Set a best time by finishing the level"


func _short_address(address: String) -> String:
	if address.length() <= 12:
		return address
	return address.substr(0, 4) + "…" + address.substr(address.length() - 4)


func _load_best() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	best_time = float(f.get_line().strip_edges())
	best_coins = int(f.get_line().strip_edges())
	f.close()


func _save_best() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_line(str(best_time))
	f.store_line(str(best_coins))
	f.close()


func _toast(message: String) -> void:
	toast_label.text = message
