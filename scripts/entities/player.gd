class_name Player
extends CharacterBody2D

const MOVE_SPEED := 260.0
const DASH_SPEED := 780.0
const DASH_DURATION := 0.14
const DASH_COOLDOWN := 0.35
const MAX_ECHOES := 5
const INVULN_AFTER_HIT := 0.85

@onready var _visual: Polygon2D = $Visual
@onready var _glow: Polygon2D = $Glow
@onready var _hitbox: Area2D = $Hurtbox
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _dash_time: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _invuln: float = 0.0
var _echo_scene: PackedScene = preload("res://scenes/entities/echo.tscn")
var _echoes: Array[Node2D] = []
var _facing: Vector2 = Vector2.RIGHT
var _alive: bool = true

func _ready() -> void:
	add_to_group("player")
	_hitbox.body_entered.connect(_on_hurtbox_body_entered)
	_hitbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta: float) -> void:
	if not _alive or not RunState.run_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_pulse_visual()

	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_dir * DASH_SPEED
		move_and_slide()
		_clamp_to_arena()
		if _dash_time <= 0.0:
			_end_dash()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length_squared() > 0.01:
		_facing = input_dir.normalized()
	velocity = input_dir * MOVE_SPEED
	move_and_slide()
	_clamp_to_arena()

	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		_start_dash(input_dir)
	if Input.is_action_just_pressed("shatter"):
		_shatter_nearest()

func _start_dash(input_dir: Vector2) -> void:
	var dir := input_dir
	if dir.length_squared() < 0.01:
		dir = _facing
	_dash_dir = dir.normalized()
	_dash_time = DASH_DURATION
	_dash_cd = DASH_COOLDOWN
	_invuln = maxf(_invuln, DASH_DURATION + 0.05)
	var from_pos := global_position
	_spawn_echo(from_pos)
	_spawn_dash_trail(from_pos)
	EventBus.player_dashed.emit(from_pos, from_pos + _dash_dir * DASH_SPEED * DASH_DURATION)
	AudioService.play_dash()
	EventBus.camera_shake_requested.emit(3.0, 0.08)

func _spawn_dash_trail(at_pos: Vector2) -> void:
	var trail := Node2D.new()
	trail.global_position = at_pos
	trail.z_index = -1
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(14, -4), Vector2(10, 14), Vector2(-10, 14), Vector2(-14, -4)
	])
	visual.color = Color(0.55, 0.85, 1.0, 0.55)
	trail.add_child(visual)
	get_parent().add_child(trail)
	var tw := trail.create_tween()
	tw.tween_property(visual, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(trail, "scale", Vector2(1.4, 1.4), 0.3)
	tw.tween_callback(trail.queue_free)

func _end_dash() -> void:
	velocity = _dash_dir * MOVE_SPEED * 0.4

func _spawn_echo(at_pos: Vector2) -> void:
	_prune_echoes()
	while _echoes.size() >= MAX_ECHOES:
		var oldest: Node2D = _echoes.pop_front()
		if is_instance_valid(oldest) and oldest.has_method("shatter"):
			oldest.call("shatter", false)
	var echo: Node2D = _echo_scene.instantiate() as Node2D
	echo.global_position = at_pos
	get_parent().add_child(echo)
	_echoes.append(echo)
	RunState.echoes_alive = _echoes.size()
	EventBus.echo_spawned.emit(echo)
	if echo.has_signal("shattered"):
		echo.shattered.connect(_on_echo_shattered.bind(echo))

func _on_echo_shattered(echo: Node2D) -> void:
	_echoes.erase(echo)
	RunState.echoes_alive = _echoes.size()

func _shatter_nearest() -> void:
	_prune_echoes()
	if _echoes.is_empty():
		return
	var best: Node2D = null
	var best_d := INF
	for e in _echoes:
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	if best:
		best.shatter(true)

func _prune_echoes() -> void:
	_echoes = _echoes.filter(func(e: Node2D) -> bool: return is_instance_valid(e))

func take_damage(amount: int = 1) -> void:
	if not _alive or _invuln > 0.0 or not RunState.run_active:
		return
	RunState.hp = max(RunState.hp - amount, 0)
	_invuln = INVULN_AFTER_HIT
	EventBus.player_hurt.emit(RunState.hp)
	EventBus.camera_shake_requested.emit(10.0, 0.18)
	EventBus.hitstop_requested.emit(0.06)
	AudioService.play_hit()
	_flash_hurt()
	if RunState.hp <= 0:
		_die()

func _die() -> void:
	_alive = false
	EventBus.player_died.emit()
	visible = false
	_collision.set_deferred("disabled", true)

func _flash_hurt() -> void:
	_visual.color = Color(1.0, 0.45, 0.55, 1.0)
	var tw := create_tween()
	tw.tween_property(_visual, "color", Color(0.55, 0.85, 1.0, 1.0), 0.25)

func _pulse_visual() -> void:
	var t := Time.get_ticks_msec() * 0.001
	_glow.scale = Vector2.ONE * (1.15 + sin(t * 4.0) * 0.05)
	modulate.a = 0.55 if _invuln > 0.0 and fmod(t * 14.0, 1.0) < 0.5 else 1.0

func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, 48.0, 1232.0)
	global_position.y = clampf(global_position.y, 48.0, 672.0)

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		take_damage(1)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_projectile"):
		take_damage(1)
		area.queue_free()
