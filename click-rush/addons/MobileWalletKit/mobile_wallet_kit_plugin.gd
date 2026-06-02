@tool
extends EditorPlugin

const PLUGIN_NAME := "MobileWalletBridge"

var _android_export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	_android_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(_android_export_plugin)


func _exit_tree() -> void:
	if _android_export_plugin != null:
		remove_export_plugin(_android_export_plugin)
		_android_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name := PLUGIN_NAME

	func _supports_platform(platform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform, debug):
		var variant := "debug" if debug else "release"
		return PackedStringArray([
			"MobileWalletKit/MobileWalletBridge/bin/%s/%s-%s.aar" % [variant, _plugin_name, variant],
		])

	func _get_android_dependencies(platform, debug):
		return PackedStringArray([
			"com.solanamobile:mobile-wallet-adapter-clientlib-ktx:2.0.3",
			"com.solanamobile:rpc-core:0.2.8",
			"com.solanamobile:rpc-solana:0.2.8",
			"com.solanamobile:rpc-ktordriver:0.2.8",
			"androidx.activity:activity-ktx:1.9.3",
			"androidx.lifecycle:lifecycle-runtime-ktx:2.8.7",
			"org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1",
		])

	func _get_name():
		return _plugin_name
