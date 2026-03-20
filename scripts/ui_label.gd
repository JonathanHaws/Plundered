extends Label

@export var key: String = ""    # The key in Save.data to display
@export var prefix: String = "" # Optional text before the value
@export var suffix: String = "" # Optional text after the value
# make an animation that plays

var last_value: int = 0
var display_value: float = 0.0

func _ready():
	last_value = Save.data.get(key, 0)
	display_value = last_value
	_update_label()

	# Update whenever save data changes
	Save.connect("save_data_updated", Callable(self, "_update_label"))

func _update_label() -> void:

	if key != "":
		text = "%s%s%s" % [prefix, str(int(display_value)), suffix]
		
	var current_value = Save.data.get(key, 0)
	if current_value > last_value:
		last_value = current_value
		$AnimationPlayer.stop()
		$AnimationPlayer.play("increase") 
		
	var tween = create_tween()
	tween.tween_property(self, "display_value", current_value, 0.3)

func _process(_delta: float) -> void:
	if key != "":
		text = "%s%s%s" % [prefix, str(int(display_value)), suffix]
