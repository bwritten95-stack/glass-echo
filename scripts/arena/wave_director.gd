class_name WaveDirector
extends Node
## Spawns escalating waves then the Mirror Warden.

const CHASER := preload("res://scenes/entities/enemy_chaser.tscn")
const SHOOTER := preload("res://scenes/entities/enemy_shooter.tscn")
const SPLITTER := preload("res://scenes/entities/enemy_splitter.tscn")
const BOSS := preload("res://scenes/entities/boss_warden.tscn")

signal all_waves_complete

@export var spawn_parent_path: NodePath

var _spawn_parent: Node2D
var _wave: int = 0
var _waiting_clear: bool = false
var _finished: bool = false
var _intermission: float = 0.0

func _ready() -> void:
	_spawn_parent = get_node(spawn_parent_path) as Node2D
	EventBus.enemy_died.connect(_on_enemy_died)

func start() -> void:
	_wave = 0
	_finished = false
	_waiting_clear = false
	_intermission = 1.0
	# CI / media: jump straight to Mirror Warden
	if "--boss-test" in OS.get_cmdline_user_args():
		_wave = 4
		_intermission = 0.35
		print("WAVE: boss-test — skipping to Mirror Warden")

func _process(delta: float) -> void:
	if not RunState.run_active or _finished:
		return
	if _intermission > 0.0:
		_intermission -= delta
		if _intermission <= 0.0:
			_begin_next_wave()
		return
	if _waiting_clear and RunState.enemies_alive <= 0:
		_waiting_clear = false
		EventBus.wave_cleared.emit(_wave)
		if _wave >= 5:
			_finished = true
			all_waves_complete.emit()
		else:
			_intermission = 1.4

func _begin_next_wave() -> void:
	_wave += 1
	RunState.wave_index = _wave
	match _wave:
		1:
			EventBus.wave_started.emit(1, "Fracture I")
			_spawn_group([CHASER, CHASER, CHASER])
		2:
			EventBus.wave_started.emit(2, "Fracture II")
			_spawn_group([CHASER, CHASER, SHOOTER, CHASER])
		3:
			EventBus.wave_started.emit(3, "Splinter")
			_spawn_group([SPLITTER, CHASER, SHOOTER, CHASER])
		4:
			EventBus.wave_started.emit(4, "Hall of Knives")
			_spawn_group([SHOOTER, SHOOTER, CHASER, CHASER, SPLITTER])
		5:
			EventBus.wave_started.emit(5, "Mirror Warden")
			_spawn_boss()
		_:
			_finished = true
			all_waves_complete.emit()
			return
	AudioService.play_wave()
	_waiting_clear = true

func _spawn_group(scenes: Array) -> void:
	var i := 0
	for packed in scenes:
		var scene: PackedScene = packed as PackedScene
		var enemy: Node2D = scene.instantiate() as Node2D
		enemy.global_position = _spawn_point(i, scenes.size())
		_spawn_parent.add_child(enemy)
		i += 1

func _spawn_boss() -> void:
	var boss := BOSS.instantiate() as Node2D
	boss.global_position = Vector2(640, 180)
	_spawn_parent.add_child(boss)

func _spawn_point(index: int, total: int) -> Vector2:
	var margin := 80.0
	var side := index % 4
	var t := float(index + 1) / float(total + 1)
	match side:
		0:
			return Vector2(lerpf(margin, 1280.0 - margin, t), margin)
		1:
			return Vector2(1280.0 - margin, lerpf(margin, 720.0 - margin, t))
		2:
			return Vector2(lerpf(margin, 1280.0 - margin, t), 720.0 - margin)
		_:
			return Vector2(margin, lerpf(margin, 720.0 - margin, t))

func _on_enemy_died(_pos: Vector2, _points: int) -> void:
	pass
