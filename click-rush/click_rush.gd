extends Control

# Click Rush — tap the moving target as many times as you can before the timer
# runs out. Connect a Seeker / MWA wallet via Mobile Wallet Kit and your final
# score is signed by the wallet as a tamper-evident high-score receipt.
#
# Fully playable without a wallet; the wallet step only runs when connected
# (and connecting requires an Android/Seeker build).

const ROUND_SECONDS := 15.0
const TARGET_SIZE := Vector2(96, 96)

var wallet_adapter: WalletAdapter

var status_label: Label
var address_label: Label
var connect_button: Button
var disconnect_button: Button
var score_label: Label
var timer_label: Label
var start_button: Button
var target_button: Button
var log_label: RichTextLabel
var play_field: Control

var score := 0
var time_left := 0.0
var playing := false


func _ready() -> void:
	randomize()
	_build_ui()
	_setup_wallet()
	_refresh_wallet_ui()
	_append_log("Press Start, then tap the target as fast as you can!")


func _process(delta: float) -> void:
	if not playing:
		return

	time_left = max(0.0, time_left - delta)
	timer_label.text = "Time %0.1f" % time_left
	if time_left <= 0.0:
		_end_round()


func _setup_wallet() -> void:
	wallet_adapter = WalletAdapter.new()
	wallet_adapter.identity_name = "Click Rush"
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
	bg.color = Color(0.08, 0.06, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)

	var title := Label.new()
	title.text = "Click Rush"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	stack.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(status_label)

	address_label = Label.new()
	address_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	address_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	stack.add_child(address_label)

	var wallet_row := HBoxContainer.new()
	wallet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	wallet_row.add_theme_constant_override("separation", 10)
	stack.add_child(wallet_row)

	connect_button = Button.new()
	connect_button.text = "Connect Wallet"
	connect_button.pressed.connect(_on_connect_pressed)
	wallet_row.add_child(connect_button)

	disconnect_button = Button.new()
	disconnect_button.text = "Disconnect"
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	wallet_row.add_child(disconnect_button)

	var hud := HBoxContainer.new()
	hud.alignment = BoxContainer.ALIGNMENT_CENTER
	hud.add_theme_constant_override("separation", 30)
	stack.add_child(hud)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 24)
	hud.add_child(score_label)

	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 24)
	hud.add_child(timer_label)

	start_button = Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(0, 52)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.pressed.connect(_on_start_pressed)
	stack.add_child(start_button)

	# The play field hosts the moving target.
	play_field = Control.new()
	play_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_field.custom_minimum_size = Vector2(0, 280)
	play_field.clip_contents = true
	stack.add_child(play_field)

	target_button = Button.new()
	target_button.text = "TAP"
	target_button.custom_minimum_size = TARGET_SIZE
	target_button.size = TARGET_SIZE
	target_button.visible = false
	target_button.pressed.connect(_on_target_tapped)
	play_field.add_child(target_button)

	log_label = RichTextLabel.new()
	log_label.fit_content = true
	log_label.scroll_active = true
	log_label.custom_minimum_size = Vector2(0, 90)
	stack.add_child(log_label)

	_refresh_hud()


func _on_start_pressed() -> void:
	score = 0
	time_left = ROUND_SECONDS
	playing = true
	start_button.disabled = true
	target_button.visible = true
	_refresh_hud()
	_move_target()
	_append_log("Go!")


func _on_target_tapped() -> void:
	if not playing:
		return
	score += 1
	_refresh_hud()
	_move_target()


func _move_target() -> void:
	var bounds := play_field.size
	if bounds == Vector2.ZERO:
		bounds = Vector2(400, 280)
	var max_x := max(0.0, bounds.x - TARGET_SIZE.x)
	var max_y := max(0.0, bounds.y - TARGET_SIZE.y)
	target_button.position = Vector2(randf() * max_x, randf() * max_y)


func _end_round() -> void:
	playing = false
	target_button.visible = false
	start_button.disabled = false
	_append_log("Time! Final score: %d" % score)
	_submit_score()


func _submit_score() -> void:
	if not wallet_adapter.is_wallet_connected():
		_append_log("Connect a wallet to sign your score.")
		return

	status_label.text = "Signing score..."
	wallet_adapter.sign_message("Click Rush score %d at %d" % [score, int(Time.get_unix_time_from_system())])


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
	_append_log("Score signed: %s" % signature.hex_encode().substr(0, 24) + "...")
	_refresh_wallet_ui()


func _on_sign_failed(error: String) -> void:
	_append_log("Could not sign score: %s" % error)
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
	else:
		status_label.text = "No wallet connected"
		address_label.text = ""


func _refresh_hud() -> void:
	score_label.text = "Score %d" % score
	timer_label.text = "Time %0.1f" % time_left


func _append_log(message: String) -> void:
	log_label.append_text("%s\n" % message)
