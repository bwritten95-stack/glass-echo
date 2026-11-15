extends Control

@onready var _title: Label = $Center/VBox/Title
@onready var _subtitle: Label = $Center/VBox/Subtitle
@onready var _play: Button = $Center/VBox/PlayButton
@onready var _settings: Button = $Center/VBox/SettingsButton
@onready var _quit: Button = $Center/VBox/QuitButton
@onready var _settings_panel: Control = $SettingsPanel
@onready var _master_slider: HSlider = $SettingsPanel/Panel/VBox/MasterRow/MasterSlider
@onready var _sfx_slider: HSlider = $SettingsPanel/Panel/VBox/SfxRow/SfxSlider
@onready var _fullscreen: CheckButton = $SettingsPanel/Panel/VBox/Fullscreen
@onready var _close_settings: Button = $SettingsPanel/Panel/VBox/CloseButton
@onready var _bg: ColorRect = $Background
@onready var _shards: Node2D = $DecorShards

func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	_play.pressed.connect(_on_play)
	_settings.pressed.connect(_on_settings)
	_quit.pressed.connect(_on_quit)
	_close_settings.pressed.connect(func() -> void: _settings_panel.visible = false)
	_master_slider.value = SettingsStore.master_volume
	_sfx_slider.value = SettingsStore.sfx_volume
	_fullscreen.button_pressed = SettingsStore.fullscreen
	_master_slider.value_changed.connect(func(v: float) -> void: SettingsStore.set_master_volume(v))
	_sfx_slider.value_changed.connect(func(v: float) -> void: SettingsStore.set_sfx_volume(v))
	_fullscreen.toggled.connect(func(on: bool) -> void: SettingsStore.set_fullscreen(on))
	_settings_panel.visible = false
	_spawn_decor()
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(_subtitle, "modulate:a", 1.0, 0.7)
	var args := OS.get_cmdline_user_args()
	if "--autoplay" in args or "--boss-test" in args:
		await get_tree().create_timer(0.7).timeout
		await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		if img:
			img.save_png("user://menu.png")
			print("MENU_CAPTURE: ", OS.get_user_data_dir(), "/menu.png")
		get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")

func _process(delta: float) -> void:
	for c in _shards.get_children():
		c.rotation += delta * float(c.get_meta("spin", 0.4))
		c.position.y += sin(Time.get_ticks_msec() * 0.001 + c.position.x) * 0.15

func _spawn_decor() -> void:
	for i in 14:
		var p := Polygon2D.new()
		var s := randf_range(6.0, 18.0)
		p.polygon = PackedVector2Array([
			Vector2(0, -s), Vector2(s * 0.6, 0), Vector2(0, s * 0.7), Vector2(-s * 0.6, 0)
		])
		p.color = Color(0.45, 0.75, 1.0, randf_range(0.08, 0.22))
		p.position = Vector2(randf_range(40, 1240), randf_range(40, 680))
		p.set_meta("spin", randf_range(-0.6, 0.6))
		_shards.add_child(p)

func _on_play() -> void:
	AudioService.play_ui()
	get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")

func _on_settings() -> void:
	AudioService.play_ui()
	_settings_panel.visible = true

func _on_quit() -> void:
	get_tree().quit()
