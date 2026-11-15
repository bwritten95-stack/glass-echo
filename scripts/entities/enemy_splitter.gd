extends EnemyBase
## Fat body that splits into two small chasers on death.

const CHASER_SCENE := preload("res://scenes/entities/enemy_chaser.tscn")

var _is_small: bool = false

func _ready() -> void:
	if _is_small:
		max_hp = 1
		move_speed = 170.0
		score_value = 50
		scale = Vector2(0.7, 0.7)
	else:
		max_hp = 3
		move_speed = 90.0
		score_value = 200
	super._ready()
	_visual.color = Color(1.0, 0.7, 0.25)

func configure_small() -> void:
	_is_small = true

func _ai(_delta: float) -> void:
	if _player and is_instance_valid(_player):
		steer_toward(_player.global_position, move_speed)

func _die() -> void:
	if not _is_small:
		_spawn_split()
	super._die()

func _spawn_split() -> void:
	for i in 2:
		var child := CHASER_SCENE.instantiate() as Node2D
		child.global_position = global_position + Vector2(randf_range(-18, 18), randf_range(-18, 18))
		get_parent().call_deferred("add_child", child)
