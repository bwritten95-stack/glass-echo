extends EnemyBase
## Aggressive seeker — walks into player and echoes (breaking glass).

func _ready() -> void:
	max_hp = 2
	move_speed = 135.0
	score_value = 100
	super._ready()
	_visual.color = Color(0.95, 0.35, 0.45)

func _ai(_delta: float) -> void:
	var target := _pick_target()
	if target != Vector2.ZERO:
		steer_toward(target, move_speed)

func _pick_target() -> Vector2:
	# Prefer nearest echo — forces player to manage glass
	var best_pos := Vector2.ZERO
	var best_d := INF
	for e in get_tree().get_nodes_in_group("echo"):
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best_pos = e.global_position
	if best_pos != Vector2.ZERO and best_d < 280.0 * 280.0:
		return best_pos
	if _player and is_instance_valid(_player):
		return _player.global_position
	return Vector2.ZERO

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _alive:
		return
	for i in get_slide_collision_count():
		var col: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = col.get_collider()
		if collider is Node and (collider as Node).is_in_group("echo") and collider.has_method("take_damage"):
			collider.call("take_damage", 1)
