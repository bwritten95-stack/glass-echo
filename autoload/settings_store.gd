extends Node
## Persists volume + display prefs to user://settings.cfg

const PATH := "user://settings.cfg"

var master_volume: float = 0.85
var sfx_volume: float = 1.0
var fullscreen: bool = false

func _ready() -> void:
	load_settings()
	apply()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(PATH)

func apply() -> void:
	var master_db := linear_to_db(clampf(master_volume, 0.0001, 1.0))
	var sfx_db := linear_to_db(clampf(sfx_volume, 0.0001, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)
	# SFX bus may not exist yet — AudioService creates it; still store value.
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, sfx_db)
	_apply_fullscreen()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply()
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply()
	save_settings()

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	save_settings()

func _apply_fullscreen() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
