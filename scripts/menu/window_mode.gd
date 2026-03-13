extends OptionButton

func _ready() -> void:
	connect("item_selected", Callable(Config, "set_window_mode"))
	var mode: int = Config.load_setting("display", "window_mode", Config.get_window_mode())
	Config.set_window_mode(mode) 
	selected = mode
