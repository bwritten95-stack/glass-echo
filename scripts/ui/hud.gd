extends CanvasLayer

@onready var _hp: Label = $Root/TopBar/HP
@onready var _wave: Label = $Root/TopBar/Wave
@onready var _score: Label = $Root/TopBar/Score
@onready var _echoes: Label = $Root/TopBar/Echoes
@onready var _banner: Label = $Root/Banner
@onready var _hint: Label = $Root/Hint

var _boss_bar: ProgressBar
var _boss: Node
var _boss_label: Label

func _ready() -> void:
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.player_hurt.connect(_on_hurt)
	EventBus.boss_spawned.connect(_on_boss)
	_banner.text = ""
	_hint.text = "WASD move · Shift/Space dash · F / Click shatter nearest echo · Esc pause"
	_build_boss_bar()
	_refresh()

func _build_boss_bar() -> void:
	_boss_label = Label.new()
	_boss_label.text = "Mirror Warden"
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.add_theme_font_size_override("font_size", 16)
	_boss_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	_boss_label.visible = false
	$Root.add_child(_boss_label)
	_boss_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_label.offset_top = 64
	_boss_label.offset_bottom = 88
	_boss_label.offset_left = -160
	_boss_label.offset_right = 160

	_boss_bar = ProgressBar.new()
	_boss_bar.min_value = 0
	_boss_bar.max_value = 22
	_boss_bar.value = 22
	_boss_bar.show_percentage = false
	_boss_bar.visible = false
	_boss_bar.custom_minimum_size = Vector2(320, 14)
	$Root.add_child(_boss_bar)
	_boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_bar.offset_top = 90
	_boss_bar.offset_bottom = 104
	_boss_bar.offset_left = -160
	_boss_bar.offset_right = 160

func _process(_delta: float) -> void:
	_refresh()
	if _boss_bar.visible:
		if _boss == null or not is_instance_valid(_boss):
			var bosses := get_tree().get_nodes_in_group("boss")
			_boss = bosses[0] if bosses.size() > 0 else null
		if _boss and is_instance_valid(_boss) and "hp" in _boss and "max_hp" in _boss:
			_boss_bar.max_value = float(_boss.get("max_hp"))
			_boss_bar.value = float(_boss.get("hp"))
		elif _boss_bar.visible and (_boss == null or not is_instance_valid(_boss)):
			_boss_bar.visible = false
			_boss_label.visible = false

func _refresh() -> void:
	_hp.text = "HP  %d/%d" % [RunState.hp, RunState.max_hp]
	_wave.text = "Wave %d" % RunState.wave_index
	_score.text = "%d" % RunState.score
	_echoes.text = "Echoes %d/5" % RunState.echoes_alive

func _on_wave_started(_idx: int, label: String) -> void:
	_banner.text = label
	_banner.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.5)

func _on_hurt(_hp_left: int) -> void:
	_refresh()

func _on_boss() -> void:
	_banner.text = "MIRROR WARDEN"
	_banner.modulate = Color(0.8, 0.95, 1.0, 1.0)
	_boss_bar.visible = true
	_boss_label.visible = true
	var bosses := get_tree().get_nodes_in_group("boss")
	_boss = bosses[0] if bosses.size() > 0 else null
	if _boss and "max_hp" in _boss:
		_boss_bar.max_value = float(_boss.get("max_hp"))
		_boss_bar.value = float(_boss.get("max_hp"))
