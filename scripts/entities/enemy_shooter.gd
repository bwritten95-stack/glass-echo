extends EnemyBase
## Keeps distance and fires slow glass-seeking bolts.

const PROJECTILE_SCENE := preload("res://scenes/entities/enemy_projectile.tscn")

var _fire_cd: float = 1.2
var _orbit_sign: float = 1.0

func _ready() -> void:
	max_hp = 2
	move_speed = 95.0
	score_value = 150
	super._ready()
	_visual.color = Color(0.55, 0.45, 1.0)
	_orbit_sign = 1.0 if randf() > 0.5 else -1.0
	_fire_cd = randf_range(0.4, 1.0)

func _ai(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	var desired := _player.global_position
	if dist < 220.0:
		desired = global_position - to_player.normalized() * 80.0
	elif dist > 340.0:
		desired = _player.global_position
	else:
		var tangent := to_player.normalized().rotated(PI * 0.5 * _orbit_sign)
		desired = global_position + tangent * 60.0
	steer_toward(desired, move_speed)
	_fire_cd -= delta
	if _fire_cd <= 0.0:
		_fire()
		_fire_cd = randf_range(1.1, 1.7)

func _fire() -> void:
	if _player == null:
		return
	var bolt := PROJECTILE_SCENE.instantiate() as Node2D
	bolt.global_position = global_position
	var dir := (_player.global_position - global_position).normalized()
	get_parent().add_child(bolt)
	if bolt.has_method("launch"):
		bolt.launch(dir * 220.0)
