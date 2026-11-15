class_name EnemyBase
extends CharacterBody2D

@export var max_hp: int = 2
@export var move_speed: float = 120.0
@export var score_value: int = 100
@export var contact_damage: int = 1

@onready var _visual: Polygon2D = $Visual

var hp: int = 2
var _player: Node2D
var _alive: bool = true
var _hurt_flash: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	RunState.enemies_alive += 1
	_find_player()

func _exit_tree() -> void:
	if _alive:
		# cleaned without dying (scene change)
		RunState.enemies_alive = max(RunState.enemies_alive - 1, 0)

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if not _alive or not RunState.run_active:
		return
	if _player == null or not is_instance_valid(_player):
		_find_player()
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	if _hurt_flash > 0.0:
		_visual.modulate = Color(1.5, 1.5, 1.5)
	else:
		_visual.modulate = Color.WHITE
	_ai(delta)
	move_and_slide()
	_keep_in_bounds()

func _ai(_delta: float) -> void:
	pass

func _keep_in_bounds() -> void:
	global_position.x = clampf(global_position.x, 40.0, 1240.0)
	global_position.y = clampf(global_position.y, 40.0, 680.0)

func take_damage(amount: int = 1) -> void:
	if not _alive:
		return
	hp -= amount
	_hurt_flash = 0.08
	EventBus.camera_shake_requested.emit(2.5, 0.05)
	if hp <= 0:
		_die()

func _die() -> void:
	_alive = false
	RunState.enemies_alive = max(RunState.enemies_alive - 1, 0)
	RunState.add_score(score_value)
	EventBus.enemy_died.emit(global_position, score_value)
	AudioService.play_enemy_die()
	_spawn_death_fx()
	queue_free()

func _spawn_death_fx() -> void:
	var fx := Polygon2D.new()
	fx.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(8, 0), Vector2(0, 10), Vector2(-8, 0)
	])
	fx.color = _visual.color
	fx.global_position = global_position
	get_parent().add_child(fx)
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector2(2.2, 2.2), 0.2)
	tw.parallel().tween_property(fx, "modulate:a", 0.0, 0.2)
	tw.tween_callback(fx.queue_free)

func steer_toward(target: Vector2, speed: float) -> void:
	var dir := (target - global_position)
	if dir.length_squared() < 1.0:
		velocity = Vector2.ZERO
		return
	velocity = dir.normalized() * speed
	rotation = lerp_angle(rotation, dir.angle() + PI * 0.5, 0.2)
