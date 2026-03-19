extends Control

func _enter_tree() -> void:
	scale = Vector2(Config.UI_SCALE, Config.UI_SCALE)

func _on_ui_scale_changed(new_scale: Vector2) -> void:
	scale = new_scale
	#print(get_parent().name, new_scale)

func _ready() -> void:
	scale = Vector2(Config.UI_SCALE, Config.UI_SCALE)
	Config.connect("ui_scale_changed", Callable(self, "_on_ui_scale_changed"))
