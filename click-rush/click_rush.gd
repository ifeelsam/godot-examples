extends Control

# Click Rush — a fast reaction game. Targets pop up, shrink, and vanish; tap them
# before they disappear to build a combo multiplier. Avoid the red bombs and don't
# miss, or you'll lose a life. Difficulty ramps the longer you survive.
#
# Connect a Seeker / MWA wallet via Mobile Wallet Kit and your final score is
# signed by the wallet as a tamper-evident high-score receipt.
#
# Fully playable without a wallet; the wallet step only runs when connected
# (and connecting requires an Android/Seeker build).

const ROUND_SECONDS := 30.0
const START_LIVES := 3
const COMBO_WINDOW := 1.25          # seconds before an idle combo decays
const MAX_MULTIPLIER := 8
const SAVE_PATH := "user://click_rush.save"

var wallet_adapter: WalletAdapter

var status_label: Label
var address_label: Label
var connect_button: Button
var disconnect_button: Button
var score_label: Label
var timer_label: Label
var combo_label: Label
var lives_label: Label
var best_label: Label
var start_button: Button
var log_label: RichTextLabel
var play_field: Control
var flash_rect: ColorRect

var score := 0
var time_left := 0.0
var elapsed := 0.0
var playing := false
var lives := 0
var combo := 0
var best_combo := 0
var combo_timer := 0.0
var spawn_timer := 0.0
var hits := 0
var misses := 0
var best_score := 0

# Each entry: {node: Button, kind: String, life: float, max_life: float,
#              base: Vector2, center: Vector2}
var targets: Array = []


func _ready() -> void:
	randomize()
	best_score = _load_best()
	_build_ui()
	_setup_wallet()
	_refresh_wallet_ui()
	_refresh_hud()
	_append_log("Tap the cyan targets before they vanish. Dodge the red bombs!")


func _process(delta: float) -> void:
	if not playing:
		return

	elapsed += delta
	time_left = max(0.0, time_left - delta)
	timer_label.text = "Time %0.1f" % time_left

	# Combo decays if you stop hitting targets.
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
			_refresh_hud()

	_update_targets(delta)

	spawn_timer -= delta
	if spawn_timer <= 0.0 and targets.size() < _max_targets():
		_spawn_target()
		spawn_timer = _spawn_interval()

	if time_left <= 0.0:
		_end_round("Time!")


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
	stack.add_theme_constant_override("separation", 10)
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
	hud.add_theme_constant_override("separation", 22)
	stack.add_child(hud)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 22)
	hud.add_child(score_label)

	combo_label = Label.new()
	combo_label.add_theme_font_size_override("font_size", 22)
	hud.add_child(combo_label)

	lives_label = Label.new()
	lives_label.add_theme_font_size_override("font_size", 22)
	hud.add_child(lives_label)

	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 22)
	hud.add_child(timer_label)

	best_label = Label.new()
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.55))
	stack.add_child(best_label)

	start_button = Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(0, 52)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.pressed.connect(_on_start_pressed)
	stack.add_child(start_button)

	# The play field hosts the moving targets. A miss inside the field (clicking
	# empty space) breaks the combo, so precision matters.
	play_field = Control.new()
	play_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_field.custom_minimum_size = Vector2(0, 320)
	play_field.clip_contents = true
	play_field.mouse_filter = Control.MOUSE_FILTER_STOP
	play_field.gui_input.connect(_on_field_input)
	stack.add_child(play_field)

	flash_rect = ColorRect.new()
	flash_rect.color = Color(1, 0, 0, 0)
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_field.add_child(flash_rect)

	log_label = RichTextLabel.new()
	log_label.fit_content = true
	log_label.scroll_active = true
	log_label.custom_minimum_size = Vector2(0, 80)
	stack.add_child(log_label)


# --- Difficulty curve (0 at start of round, ~1 near the end) ----------------

func _difficulty() -> float:
	return clamp(elapsed / ROUND_SECONDS, 0.0, 1.0)


func _spawn_interval() -> float:
	return lerp(0.85, 0.32, _difficulty())


func _target_life() -> float:
	return lerp(1.7, 0.75, _difficulty())


func _target_size() -> float:
	return lerp(112.0, 60.0, _difficulty())


func _bomb_chance() -> float:
	return lerp(0.0, 0.35, _difficulty())


func _max_targets() -> int:
	return 1 + int(_difficulty() * 3.0)


# --- Round flow -------------------------------------------------------------

func _on_start_pressed() -> void:
	_clear_targets()
	score = 0
	hits = 0
	misses = 0
	combo = 0
	best_combo = 0
	elapsed = 0.0
	time_left = ROUND_SECONDS
	lives = START_LIVES
	spawn_timer = 0.0
	playing = true
	start_button.disabled = true
	_refresh_hud()
	_append_log("Go!")


func _spawn_target() -> void:
	var bounds := play_field.size
	if bounds.x < 20.0 or bounds.y < 20.0:
		bounds = Vector2(400, 320)

	var size := _target_size()
	var base := Vector2(size, size)
	var max_x: float = max(0.0, bounds.x - size)
	var max_y: float = max(0.0, bounds.y - size)
	var center := Vector2(randf() * max_x, randf() * max_y) + base * 0.5

	var is_bomb := randf() < _bomb_chance()

	var node := Button.new()
	node.focus_mode = Control.FOCUS_NONE
	node.text = "✕" if is_bomb else "+"
	node.add_theme_font_size_override("font_size", 28)
	node.modulate = Color(1.0, 0.32, 0.32) if is_bomb else Color(0.35, 0.95, 0.85)
	node.size = base
	node.position = center - base * 0.5
	play_field.add_child(node)

	var entry := {
		"node": node,
		"kind": "bomb" if is_bomb else "good",
		"life": _target_life(),
		"max_life": _target_life(),
		"base": base,
		"center": center,
	}
	node.pressed.connect(_on_target_tapped.bind(entry))
	targets.append(entry)


func _update_targets(delta: float) -> void:
	var expired: Array = []
	for entry in targets:
		entry["life"] -= delta
		if entry["life"] <= 0.0:
			expired.append(entry)
			continue
		var ratio: float = entry["life"] / entry["max_life"]
		var cur: Vector2 = entry["base"] * (0.5 + 0.5 * ratio)
		var node: Button = entry["node"]
		node.size = cur
		node.position = entry["center"] - cur * 0.5

	for entry in expired:
		var was_good: bool = entry["kind"] == "good"
		_remove_target(entry)
		if was_good and playing:
			# Let a good target slip away → miss: break combo, lose a life.
			misses += 1
			_break_combo()
			_lose_life("A target escaped!")


func _on_target_tapped(entry: Dictionary) -> void:
	if not playing:
		return

	if entry["kind"] == "bomb":
		_remove_target(entry)
		_break_combo()
		_flash(Color(1, 0, 0, 0.45))
		_lose_life("Bomb tapped!")
		return

	hits += 1
	combo += 1
	best_combo = max(best_combo, combo)
	combo_timer = COMBO_WINDOW

	var mult := _multiplier()
	# Smaller (older) targets are worth a touch more.
	var freshness: float = 1.0 - (entry["life"] / entry["max_life"])
	var gain := int(round(10.0 * mult * (1.0 + 0.5 * freshness)))
	score += gain

	_remove_target(entry)
	_refresh_hud()


func _on_field_input(event: InputEvent) -> void:
	# A click that lands on empty field space (not a target) is a miss.
	if not playing:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		misses += 1
		_break_combo()
		_flash(Color(1, 0.6, 0, 0.25))


func _multiplier() -> int:
	return clamp(1 + int(combo / 4), 1, MAX_MULTIPLIER)


func _break_combo() -> void:
	if combo > 0:
		combo = 0
		_refresh_hud()


func _lose_life(reason: String) -> void:
	lives -= 1
	_refresh_hud()
	if lives <= 0:
		_end_round("Out of lives!")
	else:
		_append_log("%s  (%d ♥ left)" % [reason, lives])


func _end_round(reason: String) -> void:
	playing = false
	_clear_targets()
	start_button.disabled = false
	flash_rect.color.a = 0.0

	var accuracy := 0.0
	var attempts := hits + misses
	if attempts > 0:
		accuracy = 100.0 * float(hits) / float(attempts)

	_append_log("%s Score %d • best combo x%d • accuracy %0.0f%%" % [reason, score, _multiplier_for(best_combo), accuracy])

	if score > best_score:
		best_score = score
		_save_best(best_score)
		_append_log("New best score: %d!" % best_score)

	_refresh_hud()
	_submit_score()


func _multiplier_for(c: int) -> int:
	return clamp(1 + int(c / 4), 1, MAX_MULTIPLIER)


# --- Target bookkeeping -----------------------------------------------------

func _remove_target(entry: Dictionary) -> void:
	var node: Button = entry["node"]
	if is_instance_valid(node):
		node.queue_free()
	targets.erase(entry)


func _clear_targets() -> void:
	for entry in targets:
		var node: Button = entry["node"]
		if is_instance_valid(node):
			node.queue_free()
	targets.clear()


func _flash(color: Color) -> void:
	flash_rect.color = color
	var tween := create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, 0.35)


# --- Wallet -----------------------------------------------------------------

func _submit_score() -> void:
	if not wallet_adapter.is_wallet_connected():
		_append_log("Connect a wallet to sign your score.")
		return

	status_label.text = "Signing score..."
	wallet_adapter.sign_message("Click Rush score %d combo x%d at %d" % [score, best_combo, int(Time.get_unix_time_from_system())])


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


# --- HUD + persistence ------------------------------------------------------

func _refresh_hud() -> void:
	score_label.text = "Score %d" % score
	combo_label.text = "Combo x%d" % _multiplier()
	lives_label.text = "♥ %d" % max(0, lives)
	timer_label.text = "Time %0.1f" % time_left
	best_label.text = "Best %d" % best_score


func _load_best() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return 0
	var value := int(f.get_line().strip_edges())
	f.close()
	return value


func _save_best(value: int) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_line(str(value))
	f.close()


func _append_log(message: String) -> void:
	log_label.append_text("%s\n" % message)
