extends Button

func _ready() -> void:
	connect("pressed", _on_game_restart_pressed)

func _on_game_restart_pressed() -> void:
	get_tree().reload_current_scene()
