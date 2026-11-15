extends Node2D
## Short-lived afterimage spawned on dash.

func setup(poly: PackedVector2Array, tint: Color) -> void:
	var visual := Polygon2D.new()
	visual.polygon = poly
	visual.color = tint
	add_child(visual)
	var tw := create_tween()
	tw.tween_property(visual, "modulate:a", 0.0, 0.28)
	tw.parallel().tween_property(self, "scale", Vector2(1.35, 1.35), 0.28)
	tw.tween_callback(queue_free)
