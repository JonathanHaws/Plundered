extends Label

@export var key: String = ""    # The key in Save.data to display
@export var prefix: String = "" # Optional text before the value
@export var suffix: String = "" # Optional text after the value
# make an animation that plays

func _ready():
	_update_label()
	# Update whenever save data changes
	Save.connect("save_data_updated", Callable(self, "_update_label"))

func _update_label() -> void:
	if key != "":
		text = "%s%s%s" % [prefix, str(Save.data.get(key, 0)), suffix]

func _process(_delta: float) -> void:
	pass
	#print(Save.data.get("bounty", 0))
