extends SceneTree
## Headless smoke: boot menu → arena → simulate dashes → quit.
## Run: godot --headless --path . -s res://scripts/systems/smoke_test.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("SMOKE: start")
	var err := change_scene_to_file("res://scenes/arena/arena.tscn")
	if err != OK:
		push_error("SMOKE: failed to load arena: %s" % err)
		quit(1)
		return
	await process_frame
	await process_frame
	var player := root.get_node_or_null("Arena/Entities/Player")
	if player == null:
		# Player may be named differently / timing
		await create_timer(0.5).timeout
		player = _find_player()
	if player == null:
		push_error("SMOKE: player missing")
		quit(2)
		return
	print("SMOKE: player ok at ", player.global_position)
	# Simulate movement + dash via Input.parse
	for i in 8:
		_tap_key(KEY_D)
		_tap_key(KEY_SHIFT)
		await create_timer(0.2).timeout
		_tap_key(KEY_F)
		await create_timer(0.15).timeout
	print("SMOKE: echoes=", RunState.echoes_alive, " enemies=", RunState.enemies_alive, " wave=", RunState.wave_index)
	print("SMOKE: pass")
	quit(0)

func _find_player() -> Node:
	var nodes: Array[Node] = root.get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null

func _tap_key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventKey.new()
	release.physical_keycode = keycode
	release.pressed = false
	Input.parse_input_event(release)
