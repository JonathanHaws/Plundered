extends Button

func _ready() -> void:
	connect("pressed", _on_quit_pressed)

func _on_quit_pressed() -> void:
	if Config and Config.has_method("save_window_transform"): Config.save_window_transform()
	get_tree().quit()
