extends Control

# Coin Flip — a tiny, fully playable game that uses Mobile Wallet Kit for an
# optional on-chain flavored flow: connect a Seeker / MWA wallet, and every win
# is signed by the wallet as a lightweight "proof of win".
#
# The game is playable without a wallet too; wallet features simply stay idle
# until you connect (and connecting only works on an Android/Seeker build).

var wallet_adapter: WalletAdapter

var status_label: Label
var address_label: Label
var connect_button: Button
var disconnect_button: Button
var result_label: Label
var flip_button: Button
var score_label: Label
var log_label: RichTextLabel

var wins := 0
var losses := 0
var flips := 0
var awaiting_proof := false


func _ready() -> void:
	randomize()
	_build_ui()
	_setup_wallet()
	_refresh_wallet_ui()
	_append_log("Tap Flip to play. Connect a wallet to sign your wins.")


func _setup_wallet() -> void:
	wallet_adapter = WalletAdapter.new()
	wallet_adapter.identity_name = "Coin Flip"
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
	bg.color = Color(0.07, 0.09, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	margin.add_child(stack)

	var title := Label.new()
	title.text = "Coin Flip"
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

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	stack.add_child(spacer)

	result_label = Label.new()
	result_label.text = "—"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 96)
	result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack.add_child(result_label)

	flip_button = Button.new()
	flip_button.text = "Flip"
	flip_button.custom_minimum_size = Vector2(0, 64)
	flip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flip_button.pressed.connect(_on_flip_pressed)
	stack.add_child(flip_button)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(score_label)
	_refresh_score()

	log_label = RichTextLabel.new()
	log_label.fit_content = true
	log_label.scroll_active = true
	log_label.custom_minimum_size = Vector2(0, 120)
	stack.add_child(log_label)


func _on_flip_pressed() -> void:
	if awaiting_proof:
		return

	flips += 1
	var heads := randi() % 2 == 0
	result_label.text = "H" if heads else "T"

	# Simple suspense: a few quick face swaps before settling.
	for i in range(6):
		await get_tree().create_timer(0.06).timeout
		result_label.text = "H" if randi() % 2 == 0 else "T"
	result_label.text = "H" if heads else "T"

	if heads:
		wins += 1
		_append_log("Flip #%d: HEADS — you win!" % flips)
		_request_win_proof()
	else:
		losses += 1
		_append_log("Flip #%d: TAILS — you lose." % flips)

	_refresh_score()


func _request_win_proof() -> void:
	if not wallet_adapter.is_wallet_connected():
		return

	awaiting_proof = true
	flip_button.disabled = true
	status_label.text = "Signing win proof..."
	wallet_adapter.sign_message("Coin Flip win #%d at %d" % [wins, int(Time.get_unix_time_from_system())])


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
	status_label.text = "Wallet error"
	_append_log("Wallet error: %s" % error)
	_refresh_wallet_ui()


func _on_message_signed(signature: PackedByteArray) -> void:
	awaiting_proof = false
	flip_button.disabled = false
	_append_log("Win signed: %s" % signature.hex_encode().substr(0, 24) + "...")
	_refresh_wallet_ui()


func _on_sign_failed(error: String) -> void:
	awaiting_proof = false
	flip_button.disabled = false
	_append_log("Could not sign win: %s" % error)
	_refresh_wallet_ui()


func _on_disconnected() -> void:
	_append_log("Wallet disconnected.")
	_refresh_wallet_ui()


func _refresh_wallet_ui() -> void:
	var connected := wallet_adapter != null and wallet_adapter.is_wallet_connected()
	connect_button.visible = not connected
	disconnect_button.visible = connected

	if connected:
		var address := wallet_adapter.get_connected_address()
		status_label.text = "Wallet connected"
		address_label.text = address
	else:
		status_label.text = "No wallet connected"
		address_label.text = ""


func _refresh_score() -> void:
	score_label.text = "Wins %d   •   Losses %d" % [wins, losses]


func _append_log(message: String) -> void:
	log_label.append_text("%s\n" % message)
