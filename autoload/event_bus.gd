extends Node
## Global gameplay signals — keep scenes decoupled.

signal player_dashed(from_pos: Vector2, to_pos: Vector2)
signal echo_spawned(echo: Node2D)
signal echo_shattered(world_pos: Vector2, shard_count: int)
signal enemy_died(world_pos: Vector2, points: int)
signal player_hurt(remaining_hp: int)
signal player_died
signal wave_started(wave_index: int, label: String)
signal wave_cleared(wave_index: int)
signal boss_spawned
signal run_won
signal run_lost
signal camera_shake_requested(amount: float, duration: float)
signal hitstop_requested(duration: float)
