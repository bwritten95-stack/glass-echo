class_name ShardBurst
extends Node2D
## Radial damaging shards that briefly carve the arena.

const SHARD_SCENE := preload("res://scenes/entities/shard.tscn")

func setup(from_damage: bool) -> void:
	var count := 10 if from_damage else 6
	var speed := 420.0 if from_damage else 300.0
	var parent := get_parent()
	for i in count:
		var shard := SHARD_SCENE.instantiate() as Area2D
		var angle := TAU * float(i) / float(count) + randf_range(-0.08, 0.08)
		shard.global_position = global_position
		parent.add_child(shard)
		shard.launch(Vector2.from_angle(angle) * speed, true)
	queue_free()
