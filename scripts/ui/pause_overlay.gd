extends CanvasLayer

@onready var _resume: Button = $Root/Panel/VBox/Resume
@onready var _menu: Button = $Root/Panel/VBox/Menu
@onready var _vbox: VBoxContainer = $Root/Panel/VBox

var _master: HSlider
var _sfx: HSlider
var _fullscreen: CheckButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_resume.pressed.connect(_on_resume)
	_menu.pressed.connect(_on_menu)
	_build_settings_rows()

func _build_settings_rows() -> void:
	var sep := HSeparator.new()
	_vbox.add_child(sep)
	_vbox.move_child(sep, _resume.get_index())

	_master = _make_slider_row("Master", SettingsStore.master_volume, func(v: float) -> void:
		SettingsStore.set_master_volume(v)
	)
	_sfx = _make_slider_row("SFX", SettingsStore.sfx_volume, func(v: float) -> void:
		SettingsStore.set_sfx_volume(v)
	)
	_fullscreen = CheckButton.new()
	_fullscreen.text = "Fullscreen"
	_fullscreen.button_pressed = SettingsStore.fullscreen
	_fullscreen.toggled.connect(func(on: bool) -> void:
		SettingsStore.set_fullscreen(on)
	)
	_vbox.add_child(_fullscreen)
	_vbox.move_child(_fullscreen, _resume.get_index())

func _make_slider_row(title: String, value: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(70, 0)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(on_change)
	row.add_child(label)
	row.add_child(slider)
	_vbox.add_child(row)
	_vbox.move_child(row, _resume.get_index())
	return slider

func _on_resume() -> void:
	get_tree().paused = false
	visible = false
	AudioService.play_ui()

func _on_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	AudioService.play_ui()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
