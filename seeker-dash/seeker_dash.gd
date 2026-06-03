extends Control

# Seeker Dash — a side-scrolling platformer inspired by classic Mario runners.
# Run, jump, collect coins, stomp enemies, and reach the flag before time runs out.
#
# Connect a Seeker / MWA wallet via Mobile Wallet Kit to:
#   • Sign checkpoint proofs every 5 coins (mid-run wallet interaction)
#   • Sign a tamper-evident level-clear receipt at the finish line
#
# Fully playable without a wallet; wallet features stay idle until connected
# (and connecting requires an Android/Seeker build).

const WORLD_SCRIPT := preload("res://game/platform_world.gd")
const SAVE_PATH := "user://seeker_dash.save"
const CHECKPOINT_COINS := 5

var wallet_adapter: WalletAdapter

var status_label: Label
var address_label: Label
var connect_button: Button
var disconnect_button: Button
var hud_label: Label
var best_label: Label
var prompt_label: Label
var start_button: Button
var log_label: RichTextLabel
var viewport_container: SubViewportContainer
var sub_viewport: SubViewport
var world: Node2D

var left_button: Button
var right_button: Button
var jump_button: Button

var playing := false
var awaiting_sign := false
var move_left := false
var move_right := false
var jump_held := false
var last_checkpoint := 0
var best_time := 9999.0
var best_coins := 0


func _ready() -> void:
	randomize()
	_load_best()
	_build_ui()
	_setup_world()
	_setup_wallet()
	_refresh_wallet_ui()
	_refresh_hud()
	_append_log("Reach the flag at the end of the level. Stomp red enemies from above!")


func _process(_delta: float) -> void:
	if world == null:
		return

	var direction := 0.0
	if move_left:
		direction -= 1.0
	if move_right:
		direction += 1.0
	if not move_left and not move_right:
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
	bg.color = Color(0.06, 0.08, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 16)
	add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	var title := Label.new()
	title.text = "Seeker Dash"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Run • Jump • Collect • Sign"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
	stack.add_child(subtitle)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(status_label)

	address_label = Label.new()
	address_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	address_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	address_label.add_theme_font_size_override("font_size", 12)
	stack.add_child(address_label)

	var wallet_row := HBoxContainer.new()
	wallet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	wallet_row.add_theme_constant_override("separation", 8)
	stack.add_child(wallet_row)

	connect_button = Button.new()
	connect_button.text = "Connect Wallet"
	connect_button.pressed.connect(_on_connect_pressed)
	wallet_row.add_child(connect_button)

	disconnect_button = Button.new()
	disconnect_button.text = "Disconnect"
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	wallet_row.add_child(disconnect_button)

	hud_label = Label.new()
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.add_theme_font_size_override("font_size", 18)
	stack.add_child(hud_label)

	best_label = Label.new()
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.55))
	stack.add_child(best_label)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(prompt_label)

	start_button = Button.new()
	start_button.text = "Start Run"
	start_button.custom_minimum_size = Vector2(0, 48)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.pressed.connect(_on_start_pressed)
	stack.add_child(start_button)

	viewport_container = SubViewportContainer.new()
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_container.custom_minimum_size = Vector2(0, 280)
	viewport_container.stretch = true
	stack.add_child(viewport_container)

	sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2(720, 400)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.handle_input_locally = false
	viewport_container.add_child(sub_viewport)

	var touch_row := HBoxContainer.new()
	touch_row.alignment = BoxContainer.ALIGNMENT_CENTER
	touch_row.add_theme_constant_override("separation", 10)
	stack.add_child(touch_row)

	left_button = _make_touch_button("◀")
	left_button.button_down.connect(func(): move_left = true)
	left_button.button_up.connect(func(): move_left = false)
	touch_row.add_child(left_button)

	right_button = _make_touch_button("▶")
	right_button.button_down.connect(func(): move_right = true)
	right_button.button_up.connect(func(): move_right = false)
	touch_row.add_child(right_button)

	jump_button = _make_touch_button("Jump")
	jump_button.modulate = Color(0.55, 0.9, 0.75)
	jump_button.button_down.connect(func(): jump_held = true)
	jump_button.button_up.connect(func(): jump_held = false)
	touch_row.add_child(jump_button)

	log_label = RichTextLabel.new()
	log_label.fit_content = true
	log_label.scroll_active = true
	log_label.custom_minimum_size = Vector2(0, 72)
	stack.add_child(log_label)


func _make_touch_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(96, 56)
	button.focus_mode = Control.FOCUS_NONE
	return button


func _on_start_pressed() -> void:
	if playing or awaiting_sign:
		return
	playing = true
	last_checkpoint = 0
	start_button.disabled = true
	prompt_label.text = "Go! Collect coins and reach the flag."
	world.start_run()
	_append_log("Run started — good luck!")


func _on_coin_collected(total: int) -> void:
	if total > 0 and total % CHECKPOINT_COINS == 0 and total != last_checkpoint:
		last_checkpoint = total
		_append_log("Checkpoint: %d coins collected." % total)
		_sign_checkpoint(total)


func _on_enemy_stomped(_total: int) -> void:
	pass


func _on_player_died(deaths: int) -> void:
	_append_log("Ouch! Deaths: %d" % deaths)


func _on_level_finished(stats: Dictionary) -> void:
	playing = false
	start_button.disabled = false

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

	_append_log(
		"Level clear! Time %0.1fs • %d coins • %d stomps • %d deaths" % [
			time, coin_count, stomp_count, death_count
		]
	)
	prompt_label.text = "Level complete! Tap Start Run to play again."
	_sign_level_clear(stats)
	_refresh_hud()


func _sign_checkpoint(coin_total: int) -> void:
	if not wallet_adapter.is_wallet_connected():
		return
	awaiting_sign = true
	status_label.text = "Signing checkpoint..."
	wallet_adapter.sign_message(
		"Seeker Dash checkpoint coins %d deaths %d at %d" % [
			coin_total,
			world.get_hud().get("deaths", 0),
			int(Time.get_unix_time_from_system()),
		]
	)


func _sign_level_clear(stats: Dictionary) -> void:
	if not wallet_adapter.is_wallet_connected():
		_append_log("Connect a wallet to sign your level-clear proof.")
		return
	awaiting_sign = true
	status_label.text = "Signing level clear..."
	wallet_adapter.sign_message(
		"Seeker Dash clear time %0.2f coins %d stomps %d deaths %d at %d" % [
			stats.get("time", 0.0),
			stats.get("coins", 0),
			stats.get("stomps", 0),
			stats.get("deaths", 0),
			int(Time.get_unix_time_from_system()),
		]
	)


func _on_connect_pressed() -> void:
	if not wallet_adapter.is_available():
		_append_log("Wallet bridge unavailable. Export to Android/Seeker to connect.")
		return
	status_label.text = "Connecting..."
	wallet_adapter.connect_wallet()


func _on_disconnect_pressed() -> void:
	wallet_adapter.disconnect_wallet()


func _on_connected(address: String) -> void:
	_append_log("Connected: %s" % address)
	_refresh_wallet_ui()


func _on_connection_failed(error: String) -> void:
	_append_log("Wallet error: %s" % error)
	_refresh_wallet_ui()


func _on_message_signed(signature: PackedByteArray) -> void:
	awaiting_sign = false
	_append_log("Signed: %s..." % signature.hex_encode().substr(0, 24))
	_refresh_wallet_ui()


func _on_sign_failed(error: String) -> void:
	awaiting_sign = false
	_append_log("Could not sign: %s" % error)
	_refresh_wallet_ui()


func _on_disconnected() -> void:
	_append_log("Wallet disconnected.")
	_refresh_wallet_ui()


func _refresh_wallet_ui() -> void:
	var connected := wallet_adapter != null and wallet_adapter.is_wallet_connected()
	connect_button.visible = not connected
	disconnect_button.visible = connected

	if connected:
		status_label.text = "Wallet connected"
		address_label.text = wallet_adapter.get_connected_address()
	elif awaiting_sign:
		pass
	else:
		status_label.text = "No wallet connected"
		address_label.text = ""


func _refresh_hud() -> void:
	if world == null:
		return
	var hud: Dictionary = world.get_hud()
	hud_label.text = "Coins %d  •  Stomps %d  •  Deaths %d  •  Time %0.1fs" % [
		hud.get("coins", 0),
		hud.get("stomps", 0),
		hud.get("deaths", 0),
		hud.get("time", 0.0),
	]
	if best_time < 9999.0:
		best_label.text = "Best time %0.1fs  •  Best coins %d" % [best_time, best_coins]
	else:
		best_label.text = "Finish the level to set a best time."


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


func _append_log(message: String) -> void:
	log_label.append_text("%s\n" % message)
