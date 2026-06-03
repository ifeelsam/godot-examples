extends Control

# Coin Flip — a press-your-luck prediction game. You don't just flip: you CALL
# heads or tails. Every correct call doubles your pot (double-or-nothing); one
# wrong call wipes it. Cash out to bank the pot before your luck runs out.
#
# Connect a Seeker / MWA wallet via Mobile Wallet Kit and each cash-out is signed
# by the wallet as a lightweight "proof of bank".
#
# The game is fully playable without a wallet; wallet features simply stay idle
# until you connect (and connecting only works on an Android/Seeker build).

const START_BALANCE := 100
const STAKE_STEP := 10
const SAVE_PATH := "user://coin_flip.save"

var wallet_adapter: WalletAdapter

var status_label: Label
var address_label: Label
var connect_button: Button
var disconnect_button: Button
var result_label: Label
var prompt_label: Label
var balance_label: Label
var pot_label: Label
var streak_label: Label
var best_label: Label
var stake_label: Label
var stake_dec_button: Button
var stake_inc_button: Button
var heads_button: Button
var tails_button: Button
var cashout_button: Button
var refill_button: Button
var log_label: RichTextLabel

var balance := START_BALANCE
var stake := STAKE_STEP
var pot := 0
var streak := 0
var best_streak := 0
var best_bank := 0
var in_round := false
var flipping := false
var awaiting_proof := false


func _ready() -> void:
	randomize()
	_load_progress()
	_build_ui()
	_setup_wallet()
	_refresh_wallet_ui()
	_refresh_state()
	_append_log("Set a stake, then call Heads or Tails. Correct calls double your pot.")


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
	stack.add_theme_constant_override("separation", 12)
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

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 24)
	stack.add_child(stats)

	balance_label = Label.new()
	balance_label.add_theme_font_size_override("font_size", 22)
	stats.add_child(balance_label)

	pot_label = Label.new()
	pot_label.add_theme_font_size_override("font_size", 22)
	pot_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.6))
	stats.add_child(pot_label)

	streak_label = Label.new()
	streak_label.add_theme_font_size_override("font_size", 22)
	stats.add_child(streak_label)

	best_label = Label.new()
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.55))
	stack.add_child(best_label)

	result_label = Label.new()
	result_label.text = "?"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 96)
	result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack.add_child(result_label)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(prompt_label)

	# Stake selector (only matters when starting a fresh round).
	var stake_row := HBoxContainer.new()
	stake_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stake_row.add_theme_constant_override("separation", 10)
	stack.add_child(stake_row)

	stake_dec_button = Button.new()
	stake_dec_button.text = "-"
	stake_dec_button.custom_minimum_size = Vector2(48, 40)
	stake_dec_button.pressed.connect(_on_stake_changed.bind(-STAKE_STEP))
	stake_row.add_child(stake_dec_button)

	stake_label = Label.new()
	stake_label.custom_minimum_size = Vector2(140, 0)
	stake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stake_label.add_theme_font_size_override("font_size", 20)
	stake_row.add_child(stake_label)

	stake_inc_button = Button.new()
	stake_inc_button.text = "+"
	stake_inc_button.custom_minimum_size = Vector2(48, 40)
	stake_inc_button.pressed.connect(_on_stake_changed.bind(STAKE_STEP))
	stake_row.add_child(stake_inc_button)

	# Call buttons.
	var call_row := HBoxContainer.new()
	call_row.alignment = BoxContainer.ALIGNMENT_CENTER
	call_row.add_theme_constant_override("separation", 12)
	stack.add_child(call_row)

	heads_button = Button.new()
	heads_button.text = "Call Heads"
	heads_button.custom_minimum_size = Vector2(0, 60)
	heads_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heads_button.pressed.connect(_on_call.bind("H"))
	call_row.add_child(heads_button)

	tails_button = Button.new()
	tails_button.text = "Call Tails"
	tails_button.custom_minimum_size = Vector2(0, 60)
	tails_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tails_button.pressed.connect(_on_call.bind("T"))
	call_row.add_child(tails_button)

	cashout_button = Button.new()
	cashout_button.text = "Cash Out"
	cashout_button.custom_minimum_size = Vector2(0, 52)
	cashout_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cashout_button.pressed.connect(_on_cash_out)
	stack.add_child(cashout_button)

	refill_button = Button.new()
	refill_button.text = "Refill to %d" % START_BALANCE
	refill_button.pressed.connect(_on_refill)
	stack.add_child(refill_button)

	log_label = RichTextLabel.new()
	log_label.fit_content = true
	log_label.scroll_active = true
	log_label.custom_minimum_size = Vector2(0, 110)
	stack.add_child(log_label)


# --- Game flow --------------------------------------------------------------

func _on_stake_changed(delta: int) -> void:
	if in_round or flipping:
		return
	stake = clampi(stake + delta, STAKE_STEP, max(STAKE_STEP, balance))
	_refresh_state()


func _on_call(pick: String) -> void:
	if flipping or awaiting_proof:
		return

	# Starting a fresh round: take the stake from the balance into the pot.
	if not in_round:
		if balance < stake:
			_append_log("Not enough chips for that stake.")
			return
		balance -= stake
		pot = stake
		in_round = true

	_flip(pick)


func _flip(pick: String) -> void:
	flipping = true
	_refresh_state()

	# Suspense: rapid face swaps before settling.
	for i in range(8):
		await get_tree().create_timer(0.06).timeout
		result_label.text = "H" if randi() % 2 == 0 else "T"

	var landed := "H" if randi() % 2 == 0 else "T"
	result_label.text = landed
	flipping = false

	if landed == pick:
		streak += 1
		best_streak = max(best_streak, streak)
		pot *= 2
		_append_log("Landed %s — correct! Pot is now %d (streak %d)." % [landed, pot, streak])
		if best_streak == streak:
			_save_progress()
	else:
		_append_log("Landed %s — wrong. Lost a pot of %d." % [landed, pot])
		pot = 0
		streak = 0
		in_round = false

	_refresh_state()


func _on_cash_out() -> void:
	if in_round and pot > 0 and not flipping and not awaiting_proof:
		balance += pot
		var banked := pot
		var ended_streak := streak
		best_bank = max(best_bank, balance)
		pot = 0
		streak = 0
		in_round = false
		_save_progress()
		_append_log("Cashed out %d chips after a streak of %d. Balance: %d." % [banked, ended_streak, balance])
		_refresh_state()
		_sign_receipt(banked, ended_streak)


func _on_refill() -> void:
	if in_round or flipping:
		return
	balance = START_BALANCE
	pot = 0
	streak = 0
	stake = STAKE_STEP
	_append_log("Refilled to %d chips." % START_BALANCE)
	_refresh_state()


func _refresh_state() -> void:
	balance_label.text = "Balance %d" % balance
	pot_label.text = "Pot %d" % pot
	streak_label.text = "Streak %d" % streak
	best_label.text = "Best streak %d  •  Best bank %d" % [best_streak, best_bank]
	stake_label.text = "Stake %d" % stake

	var busy := flipping or awaiting_proof

	# Stake controls only apply between rounds.
	var can_stake := not in_round and not busy
	stake_dec_button.disabled = not can_stake or stake <= STAKE_STEP
	stake_inc_button.disabled = not can_stake or stake >= balance

	# You can call as long as you're not busy and (mid-round, or can afford a new stake).
	var can_call := not busy and (in_round or balance >= stake)
	heads_button.disabled = not can_call
	tails_button.disabled = not can_call

	cashout_button.disabled = busy or not in_round or pot <= 0
	cashout_button.visible = in_round
	refill_button.visible = not in_round and balance < stake

	if busy:
		prompt_label.text = "Flipping..." if flipping else "Signing receipt..."
	elif in_round:
		prompt_label.text = "Double or nothing — call it, or cash out %d." % pot
	elif balance < stake:
		prompt_label.text = "Out of chips. Refill to keep playing."
	else:
		prompt_label.text = "Call Heads or Tails to wager %d." % stake


# --- Wallet -----------------------------------------------------------------

func _sign_receipt(banked: int, ended_streak: int) -> void:
	if not wallet_adapter.is_wallet_connected():
		return
	awaiting_proof = true
	status_label.text = "Signing receipt..."
	_refresh_state()
	wallet_adapter.sign_message("Coin Flip cashout %d streak %d balance %d at %d" % [banked, ended_streak, balance, int(Time.get_unix_time_from_system())])


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
	_append_log("Receipt signed: %s" % signature.hex_encode().substr(0, 24) + "...")
	_refresh_wallet_ui()
	_refresh_state()


func _on_sign_failed(error: String) -> void:
	awaiting_proof = false
	_append_log("Could not sign receipt: %s" % error)
	_refresh_wallet_ui()
	_refresh_state()


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


# --- Persistence ------------------------------------------------------------

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	best_streak = int(f.get_line().strip_edges())
	best_bank = int(f.get_line().strip_edges())
	f.close()


func _save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_line(str(best_streak))
	f.store_line(str(best_bank))
	f.close()


func _append_log(message: String) -> void:
	log_label.append_text("%s\n" % message)
