extends Control
@export var setting_name := ""
const ENVIRONMENT_MAP := {
	"glow": "glow_enabled",
	"glow_intensity": "glow_intensity",
	"bloom": "glow_bloom",

	"brightness": "adjustment_brightness",
	"contrast": "adjustment_contrast",
	"saturation": "adjustment_saturation",
	
	"ssao_enabled": "ssao_enabled",
	"ssao_radius": "ssao_radius",
	"ssao_intensity": "ssao_intensity",
}

func get_environment() -> Environment:
	var world := get_viewport().get_world_3d()
	if not world: return null
	return world.environment
func get_environment_value(key: String) -> Variant:
	var env := get_environment()
	if env == null or not ENVIRONMENT_MAP.has(key): return null
	return env.get(ENVIRONMENT_MAP[key])
func set_environment_value(key: String, value: Variant) -> void:
	var env := get_environment()
	if env == null or not ENVIRONMENT_MAP.has(key): return
	env.set(ENVIRONMENT_MAP[key], value)

func _ready() -> void:
	
	if not toggle_button: # Auto reference to save configuration time.
		if get_parent() is CheckButton: toggle_button = get_parent()
		else: for sibling in get_parent().get_children():
			if sibling is CheckButton: toggle_button = sibling; break				
	if toggle_button:
		toggle_button.toggled.connect(_on_toggled)
		var fallback = get_environment_value(setting_name)
		toggle_button.button_pressed = fallback
		_on_toggled(Config.load_setting("display", setting_name, fallback))
	
	if not display_label: # Auto reference to save configuration time.
		if get_parent() is Label: display_label = get_parent()
		else: for sibling in get_parent().get_children():
			if sibling is Label: display_label = sibling; break		
	if display_label: prefix_text = display_label.text
#
	if not slider: # Auto reference to save configuration time.
		if get_parent() is HSlider: slider = get_parent()
		else: for sibling in get_parent().get_children():
			if sibling is HSlider: slider = sibling; break		
	if slider: 	
		slider.value_changed.connect(_on_value_changed)
		var fallback = get_environment_value(setting_name)
		slider.value = fallback
		if display_label: display_label.text = str(slider.value)
		_on_value_changed(Config.load_setting("display", setting_name, fallback))

@export_group("Toggle Button")
@export var toggle_button: CheckButton
func _on_toggled(enabled: bool) -> void:
	Config.save_setting("display", setting_name, enabled)
	set_environment_value(setting_name, enabled)

@export_group("Slider")
@export var slider: HSlider
@export var display_label: Label
@export var round_value: bool = true
@onready var prefix_text: String
func _on_value_changed(new_value: float) -> void:
	Config.save_setting("display", setting_name, new_value)
	set_environment_value(setting_name, new_value)
	if display_label: display_label.text = prefix_text + str(new_value)
	
