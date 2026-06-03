extends Node
class_name WalletAdapter

signal connection_established(address: String)
signal connection_failed(error: String)
signal message_signed(signature: PackedByteArray)
signal sign_failed(error: String)
signal transaction_signed(serialized_transaction: PackedByteArray)
signal transaction_sent(result: Dictionary)
signal transaction_failed(error: String)
signal siws_authorized(result: Dictionary)
signal siws_failed(error: String)
signal disconnected

enum Cluster {
	DEVNET,
	MAINNET,
	TESTNET,
}

const PLUGIN_SINGLETON := "MobileWalletBridge"

@export var cluster: Cluster = Cluster.MAINNET
@export var identity_name := "Lattice"
@export var identity_uri := "https://lattice.example"
@export var icon_uri := "favicon.ico"

var _bridge = null


func _ready() -> void:
	_bridge = _resolve_bridge()
	set_process(true)


func _process(_delta: float) -> void:
	if _bridge == null:
		_bridge = _resolve_bridge()
		return

	var raw_events: String = _bridge.call("drainEvents")
	if raw_events.is_empty() or raw_events == "[]":
		return

	var parsed = JSON.parse_string(raw_events)
	if parsed is Array:
		for entry in parsed:
			if entry is Dictionary:
				_dispatch_event(entry)


func is_available() -> bool:
	if _bridge == null:
		_bridge = _resolve_bridge()
	return _bridge != null


func is_wallet_connected() -> bool:
	if _bridge == null:
		_bridge = _resolve_bridge()
	if _bridge == null:
		return false
	return not String(_bridge.call("getConnectedAddress")).is_empty()


func get_connected_address() -> String:
	if _bridge == null:
		_bridge = _resolve_bridge()
	if _bridge == null:
		return ""
	return String(_bridge.call("getConnectedAddress"))


func get_auth_token() -> String:
	if _bridge == null:
		_bridge = _resolve_bridge()
	if _bridge == null:
		return ""
	return String(_bridge.call("getAuthToken"))


func connect_wallet() -> void:
	if _bridge == null:
		_bridge = _resolve_bridge()
	if _bridge == null:
		emit_signal("connection_failed", "MobileWalletBridge Android plugin is not available.")
		return

	_bridge.call("connectWallet", int(cluster), identity_uri, icon_uri, identity_name)


func sign_message(message: String) -> void:
	if _bridge == null:
		_bridge = _resolve_bridge()
	if _bridge == null:
		emit_signal("sign_failed", "MobileWalletBridge Android plugin is not available.")
		return

	_bridge.call("signMessage", message)


func sign_transaction(serialized_transaction: PackedByteArray) -> void:
	if _bridge == null:
		_bridge = _resolve_bridge()
	if _bridge == null:
		emit_signal("transaction_failed", "MobileWalletBridge Android plugin is not available.")
		return
	if serialized_transaction.is_empty():
		emit_signal("transaction_failed", "Serialized transaction payload is empty.")
		return

	_bridge.call("signTransaction", serialized_transaction)


func sign_and_send_transaction(serialized_transaction: PackedByteArray) -> void:
	if _bridge == null:
		_bridge = _resolve_bridge()
	if _bridge == null:
		emit_signal("transaction_failed", "MobileWalletBridge Android plugin is not available.")
		return
	if serialized_transaction.is_empty():
		emit_signal("transaction_failed", "Serialized transaction payload is empty.")
		return

	_bridge.call("signAndSendTransaction", serialized_transaction)


func sign_and_send_transaction_base64(serialized_transaction_base64: String) -> void:
	var decoded_bytes := _decode_base64_bytes(serialized_transaction_base64)
	if not serialized_transaction_base64.is_empty() and decoded_bytes.is_empty():
		emit_signal("transaction_failed", "Serialized transaction is not valid base64.")
		return

	sign_and_send_transaction(decoded_bytes)


func authorize_siws(domain: String, statement: String) -> void:
	if _bridge == null:
		_bridge = _resolve_bridge()
	if _bridge == null:
		emit_signal("siws_failed", "MobileWalletBridge Android plugin is not available.")
		return

	_bridge.call(
		"authorizeSiws",
		int(cluster),
		identity_uri,
		icon_uri,
		identity_name,
		domain,
		statement
	)


func disconnect_wallet() -> void:
	if _bridge != null:
		_bridge.call("disconnectWallet")


func _resolve_bridge():
	if Engine.has_singleton(PLUGIN_SINGLETON):
		return Engine.get_singleton(PLUGIN_SINGLETON)
	return null


func _dispatch_event(event: Dictionary) -> void:
	var event_type := String(event.get("type", ""))
	var payload: Dictionary = event.get("payload", {})

	match event_type:
		"connection_established":
			emit_signal("connection_established", String(payload.get("address", "")))
		"connection_failed":
			emit_signal("connection_failed", String(payload.get("error", "Wallet connection failed.")))
		"message_signed":
			emit_signal("message_signed", _decode_base64_bytes(payload.get("signature", "")))
		"sign_failed":
			emit_signal("sign_failed", String(payload.get("error", "Message signing failed.")))
		"transaction_signed":
			emit_signal("transaction_signed", _decode_base64_bytes(payload.get("transaction", "")))
		"transaction_sent":
			var result := payload.duplicate(true)
			if result.has("signature"):
				result["signature"] = _decode_base64_bytes(result.get("signature", ""))
			emit_signal("transaction_sent", result)
		"transaction_failed":
			emit_signal("transaction_failed", String(payload.get("error", "Transaction failed.")))
		"siws_authorized":
			var result := payload.duplicate(true)
			for key in ["signature", "signed_message", "public_key"]:
				if result.has(key):
					result[key] = _decode_base64_bytes(result.get(key, ""))
			emit_signal("siws_authorized", result)
		"siws_failed":
			emit_signal("siws_failed", String(payload.get("error", "SIWS authorization failed.")))
		"disconnected":
			emit_signal("disconnected")


func _decode_base64_bytes(value: Variant) -> PackedByteArray:
	var encoded := String(value)
	if encoded.is_empty():
		return PackedByteArray()
	return Marshalls.base64_to_raw(encoded)
