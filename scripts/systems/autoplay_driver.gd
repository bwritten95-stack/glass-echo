class_name AutoplayDriver
extends Node
## Bot for CI/screenshots. Args: --autoplay [--boss-test] [--force-win] [--force-lose]

var _time: float = 0.0
var _shot_arena: bool = false
var _shot_boss: bool = false
var _held: Dictionary = {}
var _force_done: bool = false

func _ready() -> void:
	if not _has_arg("--autoplay"):
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("AUTOPLAY: enabled args=", OS.get_cmdline_user_args())
	if _has_arg("--force-win"):
		# Don't let autoplay deaths spoil the win capture
		RunState.hp = RunState.max_hp
		call_deferred("_arm_player_invuln")

func _arm_player_invuln() -> void:
	var p := _player()
	if p:
		p.set("_invuln", 9999.0)
		p.set("_alive", true)
		RunState.hp = RunState.max_hp

func _has_arg(name: String) -> bool:
	return name in OS.get_cmdline_user_args()

func _process(delta: float) -> void:
	_time += delta
	_release_all()

	var player := _player()
	if player == null:
		return

	var target := _combat_target(player as Node2D)
	if target != Vector2.ZERO:
		var dir := (target - (player as Node2D).global_position)
		if dir.length() > 8.0:
			_hold_dir(dir.normalized())
	else:
		var sector := int(_time * 1.5) % 4
		match sector:
			0: _hold("move_right")
			1: _hold("move_down")
			2: _hold("move_left")
			3: _hold("move_up")

	if fmod(_time, 0.45) < delta:
		_tap("dash")
	if fmod(_time, 0.7) < delta:
		_tap("shatter")

	if _time > 2.0 and not _shot_arena and not _has_arg("--boss-test"):
		_shot_arena = true
		await _capture("arena-combat")

	if RunState.wave_index >= 5 and not _shot_boss:
		_shot_boss = true
		await get_tree().create_timer(0.8).timeout
		await _capture("boss-warden")

	if _has_arg("--force-win") and not _force_done and _time > 3.5:
		_force_done = true
		# Keep player alive so win isn't raced by a death
		RunState.hp = RunState.max_hp
		if player.has_method("set"):
			player.set("_invuln", 999.0)
			player.set("_alive", true)
		await _capture("boss-warden")
		_kill_all_enemies()
		await get_tree().create_timer(0.6).timeout
		if RunState.run_active and RunState.outcome == "":
			RunState.mark_won()
			EventBus.run_won.emit()
			Engine.time_scale = 1.0
			get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")
		print("AUTOPLAY: force-win triggered outcome=", RunState.outcome)

	if _has_arg("--force-lose") and not _force_done and _time > 2.5:
		_force_done = true
		await _capture("arena-combat")
		RunState.hp = 0
		EventBus.player_hurt.emit(0)
		EventBus.player_died.emit()
		print("AUTOPLAY: force-lose triggered")

	var limit := 28.0 if _has_arg("--boss-test") else 10.0
	if _has_arg("--force-win") or _has_arg("--force-lose"):
		limit = 12.0
	if _time > limit:
		print("AUTOPLAY: done wave=", RunState.wave_index, " score=", RunState.score, " hp=", RunState.hp, " enemies=", RunState.enemies_alive, " outcome=", RunState.outcome)
		if RunState.run_active:
			get_tree().quit(0)

func _player() -> Node:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null

func _combat_target(player: Node2D) -> Vector2:
	var best := Vector2.ZERO
	var best_d := INF
	for group in ["boss", "enemy"]:
		for n in get_tree().get_nodes_in_group(group):
			if not is_instance_valid(n) or not (n is Node2D):
				continue
			var d := player.global_position.distance_squared_to((n as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = (n as Node2D).global_position
	return best

func _hold_dir(dir: Vector2) -> void:
	if absf(dir.x) >= absf(dir.y):
		_hold("move_right" if dir.x > 0.0 else "move_left")
	else:
		_hold("move_down" if dir.y > 0.0 else "move_up")

func _hold(action: String) -> void:
	if _held.get(action, false):
		return
	Input.action_press(action)
	_held[action] = true

func _release_all() -> void:
	for action in _held.keys():
		if _held[action]:
			Input.action_release(action)
	_held.clear()

func _tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)

func _kill_all_enemies() -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(n) and n.has_method("take_damage"):
			# Overwhelm HP
			for i in 40:
				if not is_instance_valid(n):
					break
				n.call("take_damage", 1)

func _capture(label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var tex := get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return
	var path := "user://%s.png" % label
	var err := img.save_png(path)
	print("AUTOPLAY: screenshot %s err=%s" % [path, err])
