extends Control
@export var increase_button: Button 
@export var decrease_button: Button 
@export var resolution_label: Label
@export var option_button: OptionButton 

var resolution_index: int = 0
var resolutions = {
	#"3840x2160": Vector2i(3840,2160),  # 4K
	#"2560x1440": Vector2i(2560,1440),  # QHD
	"1920x1080": Vector2i(1920,1080),  # FHD
	"1600x900": Vector2i(1600,900),
	"1440x900": Vector2i(1440,900),
	"1366x768": Vector2i(1366,768),
	"1280x800": Vector2i(1280,800),
	"1280x720": Vector2i(1280,720),
	"1024x768": Vector2i(1024,768),
	"1024x600": Vector2i(1024,600),
	"800x600": Vector2i(800,600),
	"800x480": Vector2i(800,480),
	"640x480": Vector2i(640,480),
	"480x320": Vector2i(480,320),
	"320x240": Vector2i(320,240),
	#"240x160": Vector2i(240,160),
	#"160x120": Vector2i(160,120),
	#"128x96": Vector2i(128,96),
	#"64x48": Vector2i(64,48),
}

func update_label() -> void:
	var key_text = resolutions.keys() 
	if resolution_label: resolution_label.text = key_text[resolution_index]
	
func increase_resolution() -> void:
	var keys = resolutions.keys()
	if resolution_index > 0:
		resolution_index -= 1
		var key = keys[resolution_index]
		Config.set_resolution(resolutions[key])
		if option_button: option_button.selected = resolution_index
		update_label()

func decrease_resolution() -> void:
	var keys = resolutions.keys()
	if resolution_index < keys.size() - 1:
		resolution_index += 1
		var key = keys[resolution_index]
		Config.set_resolution(resolutions[key])
		if option_button: option_button.selected = resolution_index
		update_label()
		
func _on_option_selected(index: int) -> void:
	resolution_index = index
	update_label()
	Config.set_resolution(resolutions[option_button.get_item_text(index)])

func _ready() -> void:
	
	if increase_button: increase_button.pressed.connect(increase_resolution)
	if decrease_button: decrease_button.pressed.connect(decrease_resolution)
	
	if option_button:
		for key in resolutions: option_button.add_item(key)
		option_button.item_selected.connect(_on_option_selected)
		
	get_closest_resolution()

func get_closest_resolution() -> void:
	var current = get_viewport_rect().size
	var min_diff := INF

	var keys = resolutions.keys()  # list of keys for numeric indexing
	for i in range(keys.size()):  # numeric loop
		var key = keys[i]
		var res_size = resolutions[key]
		var diff = abs(res_size.x - current.x) + abs(res_size.y - current.y)
		if diff < min_diff:
			min_diff = diff
			resolution_index = i
			
	if option_button: option_button.selected = resolution_index
	update_label()
			


	
