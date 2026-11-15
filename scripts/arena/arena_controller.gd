extends Node2D
## Root arena: wires juice, win/lose, pause.

@onready var _entities: Node2D = $Entities
@onready var _player_spawn: Marker2D = $PlayerSpawn
@onready var _wave_director: WaveDirector = $WaveDirector
@onready var _hud: CanvasLayer = $HUD
@onready var _pause_overlay: CanvasLayer = $PauseOverlay
@onready var _camera: Camera2D = $Camera2D
@onready var _bg: Node2D = $Background

var _player_scene: PackedScene = preload("res://scenes/entities/player.tscn")
var _shake_amt: float = 0.0
var _shake_time: float = 0.0
var _hitstop: float = 0.0
var _ended: bool = false

func _ready() -> void:
	RunState.reset()
	_pause_overlay.visible = false
	EventBus.camera_shake_requested.connect(_on_shake)
	EventBus.hitstop_requested.connect(_on_hitstop)
	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_died.connect(_on_enemy_died)
	_wave_director.all_waves_complete.connect(_on_all_waves_complete)
	_spawn_player()
	_wave_director.start()
	_paint_background()
	_maybe_start_autoplay()

func _maybe_start_autoplay() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			var driver := preload("res://scripts/systems/autoplay_driver.gd").new()
			add_child(driver)
			return

func _spawn_player() -> void:
	var player := _player_scene.instantiate() as Node2D
	player.global_position = _player_spawn.global_position
	_entities.add_child(player)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and RunState.run_active and not _ended:
		_toggle_pause()

	if _hitstop > 0.0:
		_hitstop -= delta
		Engine.time_scale = 0.15
	else:
		Engine.time_scale = 1.0

	if _shake_time > 0.0:
		_shake_time -= delta
		_camera.offset = Vector2(
			randf_range(-_shake_amt, _shake_amt),
			randf_range(-_shake_amt, _shake_amt)
		)
		_shake_amt = lerpf(_shake_amt, 0.0, 6.0 * delta)
	else:
		_camera.offset = Vector2.ZERO

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_pause_overlay.visible = paused
	_pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _on_shake(amount: float, duration: float) -> void:
	_shake_amt = maxf(_shake_amt, amount)
	_shake_time = maxf(_shake_time, duration)

func _on_hitstop(duration: float) -> void:
	_hitstop = maxf(_hitstop, duration)

func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	RunState.mark_lost()
	EventBus.run_lost.emit()
	AudioService.play_lose()
	await get_tree().create_timer(0.8).timeout
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")

func _on_enemy_died(pos: Vector2, points: int) -> void:
	var fx_script: GDScript = preload("res://scripts/ui/floating_text.gd")
	var fx: Node2D = fx_script.new() as Node2D
	fx.global_position = pos
	_entities.add_child(fx)
	fx.call("setup", "+%d" % points, Color(0.85, 0.95, 1.0))

func _on_all_waves_complete() -> void:
	if _ended:
		return
	_ended = true
	RunState.mark_won()
	RunState.add_score(1000)
	EventBus.run_won.emit()
	AudioService.play_win()
	EventBus.camera_shake_requested.emit(12.0, 0.35)
	await get_tree().create_timer(1.2).timeout
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")

func _paint_background() -> void:
	for child in _bg.get_children():
		child.queue_free()
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)
	])
	floor_poly.color = Color(0.045, 0.06, 0.095)
	_bg.add_child(floor_poly)
	# Concentric mirror discs
	for i in 4:
		var disc := Polygon2D.new()
		var r := 90.0 + float(i) * 70.0
		var pts := PackedVector2Array()
		for a in 48:
			pts.append(Vector2(640, 360) + Vector2.from_angle(TAU * float(a) / 48.0) * r)
		disc.polygon = pts
		disc.color = Color(0.15, 0.35, 0.55, 0.035 + float(i) * 0.01)
		_bg.add_child(disc)
	for x in range(0, 1281, 64):
		var line := Polygon2D.new()
		line.polygon = PackedVector2Array([
			Vector2(x, 0), Vector2(x + 1, 0), Vector2(x + 1, 720), Vector2(x, 720)
		])
		line.color = Color(0.14, 0.22, 0.34, 0.28)
		_bg.add_child(line)
	for y in range(0, 721, 64):
		var line := Polygon2D.new()
		line.polygon = PackedVector2Array([
			Vector2(0, y), Vector2(1280, y), Vector2(1280, y + 1), Vector2(0, y + 1)
		])
		line.color = Color(0.14, 0.22, 0.34, 0.28)
		_bg.add_child(line)
	var rim_color := Color(0.35, 0.7, 1.0, 0.18)
	for edge in [
		[Vector2(16, 16), Vector2(1264, 16), Vector2(1264, 22), Vector2(16, 22)],
		[Vector2(16, 698), Vector2(1264, 698), Vector2(1264, 704), Vector2(16, 704)],
		[Vector2(16, 16), Vector2(22, 16), Vector2(22, 704), Vector2(16, 704)],
		[Vector2(1258, 16), Vector2(1264, 16), Vector2(1264, 704), Vector2(1258, 704)]
	]:
		var rim := Polygon2D.new()
		rim.polygon = PackedVector2Array(edge)
		rim.color = rim_color
		_bg.add_child(rim)
	# Corner glow accents
	for corner in [Vector2(0, 0), Vector2(1280, 0), Vector2(0, 720), Vector2(1280, 720)]:
		var glow := Polygon2D.new()
		glow.polygon = PackedVector2Array([
			corner,
			corner + Vector2(180 if corner.x < 640 else -180, 0),
			corner + Vector2(0, 180 if corner.y < 360 else -180)
		])
		glow.color = Color(0.2, 0.45, 0.75, 0.07)
		_bg.add_child(glow)
