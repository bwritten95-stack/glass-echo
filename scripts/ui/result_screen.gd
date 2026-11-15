extends Control

@onready var _title: Label = $Center/VBox/Title
@onready var _score: Label = $Center/VBox/Score
@onready var _detail: Label = $Center/VBox/Detail
@onready var _again: Button = $Center/VBox/Again
@onready var _menu: Button = $Center/VBox/Menu

func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	var won := RunState.outcome == "won"
	_title.text = "WARDEN SHATTERED" if won else "REFLECTION LOST"
	_title.modulate = Color(0.7, 0.95, 1.0) if won else Color(1.0, 0.55, 0.6)
	_score.text = "Score  %d" % RunState.score
	_detail.text = "Wave reached: %d" % RunState.wave_index
	_again.pressed.connect(func() -> void:
		AudioService.play_ui()
		get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")
	)
	_menu.pressed.connect(func() -> void:
		AudioService.play_ui()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	# Media / CI capture
	var args := OS.get_cmdline_user_args()
	if "--autoplay" in args:
		await get_tree().create_timer(0.5).timeout
		await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		if img:
			var name := "result-win" if won else "result-lose"
			img.save_png("user://%s.png" % name)
			print("RESULT_CAPTURE: ", name, " outcome=", RunState.outcome)
		await get_tree().create_timer(0.4).timeout
		get_tree().quit(0)
