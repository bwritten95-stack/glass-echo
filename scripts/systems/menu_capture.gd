extends Node
## Attach temporarily / run via autoplay on menu: captures title screen.

func _ready() -> void:
	await get_tree().create_timer(0.8).timeout
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	if img:
		var path := "user://menu.png"
		img.save_png(path)
		print("MENU_CAPTURE: ", path, " -> ", OS.get_user_data_dir())
	if "--autoplay" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")
