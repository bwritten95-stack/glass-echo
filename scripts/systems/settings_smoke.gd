extends SceneTree
## Verifies SettingsStore round-trip. godot --headless --path . -s res://scripts/systems/settings_smoke.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Autoloads unavailable in -s mode on some setups; instantiate store directly.
	var store_script: GDScript = load("res://autoload/settings_store.gd") as GDScript
	var store: Node = store_script.new()
	root.add_child(store)
	store.set("master_volume", 0.42)
	store.set("sfx_volume", 0.63)
	store.set("fullscreen", false)
	store.call("save_settings")
	store.set("master_volume", 0.1)
	store.set("sfx_volume", 0.1)
	store.call("load_settings")
	var master: float = float(store.get("master_volume"))
	var sfx: float = float(store.get("sfx_volume"))
	print("SETTINGS_SMOKE: master=", master, " sfx=", sfx)
	if absf(master - 0.42) > 0.001 or absf(sfx - 0.63) > 0.001:
		push_error("SETTINGS_SMOKE: persist failed")
		quit(1)
		return
	print("SETTINGS_SMOKE: pass")
	quit(0)
