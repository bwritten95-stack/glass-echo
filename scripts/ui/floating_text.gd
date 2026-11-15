extends Node2D

func setup(text: String, color: Color = Color(0.85, 0.95, 1.0)) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -10)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	z_index = 20
	var tw := create_tween()
	tw.tween_property(self, "position", position + Vector2(0, -42), 0.55).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tw.tween_callback(queue_free)
