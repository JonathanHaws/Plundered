extends Node

#region Config 

func load_setting(section: String, key: String, default_value: Variant) -> Variant:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		return config.get_value(section, key, default_value)
	return default_value

func save_setting(section: String, key: String, value: Variant) -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value(section, key, value)
	config.save("user://settings.cfg")	

#endregion

#region Animations

# For triggering animations remotely like disabling input... 
# Also used by this script to trigger an animation only when the game first launches
func play_animation_by_group(animation_name: String, group_name: String = "input_anim") -> void:
	#print(animation_name)
	for p in get_tree().get_nodes_in_group(group_name):
		if p is AnimationPlayer:
			p.play(animation_name, 0)
			p.advance(p.current_animation_length)

#endregion

#region Audio

class Bus: # Wrapper class which makes buses easily savable and tweenable
	var name: String
	var index: int
	var saved: float
	var multiplier: float
	var tween: Tween = null
	func _init(bus_name: String, saved_value: float = 100.0, multiplier_value: float = 1.0) -> void:
		name = bus_name
		index = AudioServer.get_bus_index(bus_name)
		saved = saved_value
		multiplier = multiplier_value
	func apply() -> void:
		var final_volume = clamp((saved / 100.0) * multiplier, 0.0001, 1.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(final_volume))

var BUSES: Dictionary = {
	"Master": Bus.new("Master"),
	"Music":  Bus.new("Music"),
	"SFX":    Bus.new("SFX")
	}

func load_audio_settings() -> void:
	for bus_name in BUSES.keys():
		var bus = BUSES[bus_name]
		bus.saved = load_setting("audio", bus_name, bus.saved)
		bus.apply() 

func tween_bus_volume(bus_name: String, target_multiplier: float, duration_seconds: float) -> void:
	if not BUSES.has(bus_name): return
	var bus = BUSES[bus_name]
	if bus.tween:
		bus.tween.kill()
		bus.tween = null

	var start_multiplier = bus.multiplier
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	bus.tween = tween
	tween.tween_method( func(t):
		#print(bus.multiplier)
		bus.multiplier = lerp(start_multiplier, target_multiplier, t)
		bus.apply(),  
		0.0, 1.0, duration_seconds)
	tween.finished.connect(func(): bus.tween = null)
	
#endregion

#region Graphics

#region UI Scale
var BASE_UI_SCALE = 1.0
var UI_SCALE = 1
signal ui_scale_changed(new_scale: Vector2)
func set_ui_scale(value: float) -> void:
	for node in get_tree().get_nodes_in_group("ui_scalable"):
		node.scale = Vector2(value, value)
		#print('being changed')
		#print(get_parent().name)
	UI_SCALE = value
	emit_signal("ui_scale_changed", Vector2(value, value))
	#reduce_ui_scale_until_contained()

#func reduce_ui_scale_until_contained() -> void:
	#var win_size = get_window().content_scale_size
	#while true:
		#var rect = Rect2()
		#for node in get_tree().get_nodes_in_group("ui_scalable"):
			#if node is Control:
				#rect = rect.merge(node.get_global_rect())
		#if rect.end.x <= win_size.x and rect.end.y <= win_size.y: break
		#Config.UI_SCALE -= 0.05
		#for node in get_tree().get_nodes_in_group("ui_scalable"):
			#node.scale = Vector2(Config.UI_SCALE, Config.UI_SCALE)

#endregion

#region Resolution
var BASE_RES 
func set_resolution(res_size: Vector2) -> void: 
	get_window().content_scale_size = res_size
	save_setting("display", "resolution_width", res_size.x)
	save_setting("display", "resolution_height", res_size.y)
	var diff = (res_size.x / BASE_RES.x + res_size.y / BASE_RES.y) * 0.5
	UI_SCALE = BASE_UI_SCALE * diff
	set_ui_scale(UI_SCALE)
func load_resolution() -> void:
	BASE_RES = Vector2( ## Force max resolution to be 1920*1080 memoery seems to run out for audio otherwise
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	var width = load_setting("display", "resolution_width", get_window().size.x)
	var height = load_setting("display", "resolution_height", get_window().size.y)
	set_resolution(Vector2i(min(width, 1920), min(height, 1080))) 
#endregion

#region Window
var _window_save_timer: Timer = null
var _window_save_time: float = 0.3
func get_window_mode() -> int: return DisplayServer.window_get_mode()
func set_window_mode(index: int) -> void:
	save_setting("display", "window_mode", index)
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)	
func save_window_position() -> void:
	save_setting("display", "window_x", get_window().position.x)
	save_setting("display", "window_y", get_window().position.y)
func save_window_size() -> void:
	save_setting("display", "window_width", get_window().size.x)
	save_setting("display", "window_height", get_window().size.y)
func load_window_position() -> void:
	var x = load_setting("display", "window_x", get_window().position.x)
	var y = load_setting("display", "window_y", get_window().position.y)
	get_window().position = Vector2(x, y)
func load_window_size() -> void:
	var w = load_setting("display", "window_width", get_window().size.x)
	var h = load_setting("display", "window_height", get_window().size.y)
	get_window().size = Vector2(w, h)	
func save_window_transform() -> void:
	save_window_position()
	save_window_size()
func load_window_transform() -> void:
	load_window_position()
	load_window_size()
func _on_window_size_changed() -> void:
	if not _window_save_timer:
		_window_save_timer = Timer.new()
		_window_save_timer.one_shot = true
		_window_save_timer.autostart = false
		_window_save_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_window_save_timer)
		_window_save_timer.timeout.connect(func() -> void:
			save_window_transform()
			_window_save_timer.queue_free()
			_window_save_timer = null
			#print('saving window position and scale')
		)
	_window_save_timer.start(_window_save_time) 
func load_graphics_settings() -> void:
	set_window_mode(load_setting("display", "window_mode", 1))
	load_window_transform()
	load_resolution()
#endregion

#endregion

#region Controls

const JOYPAD_BUTTON_NAMES := {
	0: "PAD A",
	1: "PAD B",
	2: "PAD X",
	3: "PAD Y",
	4: "Select",
	5: "Start",
	6: "Select",
	7: "LS",
	8: "RS",
	9: "LB",
	10: "RB",
	11: "DP Up",
	12: "DP Down",
	13: "DP Left",
	14: "DP Right",
	}

const JOYPAD_AXIS_NAMES := {
	2: "LStick",
	3: "RStick",
	4: "LT",
	5: "RT",
	}

func get_event_from_string(s: String) -> InputEvent:
	var event: InputEvent = null
	if s.begins_with("Mouse "):
		event = InputEventMouseButton.new()
		event.button_index = int(s.split(" ")[1])
	elif JOYPAD_BUTTON_NAMES.values().has(s):
		event = InputEventJoypadButton.new()
		event.button_index = JOYPAD_BUTTON_NAMES.find_key(s)
	elif JOYPAD_AXIS_NAMES.values().has(s):
		event = InputEventJoypadMotion.new()
		event.axis = JOYPAD_AXIS_NAMES.find_key(s)
		event.axis_value = 1.0  # trigger press
	else:
		var code: int = OS.find_keycode_from_string(s)
		if code != 0:
			event = InputEventKey.new()
			event.keycode = code
	return event

func get_string_from_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var code = event.keycode if event.keycode != 0 else event.physical_keycode
		return OS.get_keycode_string(code)
	elif event is InputEventJoypadButton:
		return JOYPAD_BUTTON_NAMES.get(event.button_index, str(event.button_index))
	elif event is InputEventJoypadMotion:
		return JOYPAD_AXIS_NAMES.get(event.axis, str(event.axis))
	elif event is InputEventMouseButton:
		return "Mouse " + str(event.button_index)
	return "(Unknown)"

func get_string_from_action(action: String) -> String:
	var keys := []
	for event in InputMap.action_get_events(action):
		keys.append(get_string_from_event(event))
	return ", ".join(keys) if keys.size() > 0 else "(Unassigned)"

func get_events_from_string(s: String) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	for part in s.split(","):
		var event = get_event_from_string(part.strip_edges())
		if event: events.append(event)
	return events

func load_action_setting(action: String) -> void:
	var saved_string: String = load_setting("controls", action, "default")
	if saved_string != "default":
		InputMap.action_erase_events(action)
		var events = get_events_from_string(saved_string)
		for event in events: InputMap.action_add_event(action, event)

func save_action_setting(action: String) -> void:
	# Convert current InputMap state to a string and save
	var current_binds = get_string_from_action(action)
	save_setting("controls", action, current_binds)

func load_controls_settings() -> void:
	var actions = [
		"lock_on", 
		"keyboard_forward", 
		"keyboard_back", 
		"keyboard_left", 
		"keyboard_right", 
		"jump", 
		"walk", 
		"attack", 
		"block", 
		"shoot", 
		"descend", 
		"interact", 
		"heal", 
		"dash", 
		"rest", 
		"interact", 
		]
	for action in actions: load_action_setting(action)
	
#endregion

#region  Hidden Cursor
var last_position_visible :Vector2 = Vector2.ZERO
var mouse_tolerance: float = 10.0  # pixels
var idle_time_seconds: float = 0.0
var idle_timeout_seconds: float = 2.0
func hidden_cursor_ready() -> void:
	await get_tree().process_frame
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	idle_time_seconds = idle_timeout_seconds + 1
func hidden_cursor_process(_delta):
	#print(Input.get_mouse_mode())
	#print(idle_time_seconds)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		idle_time_seconds += _delta
		if idle_time_seconds >= idle_timeout_seconds:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			idle_time_seconds = 0
func hidden_cursor_input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: return
	if event is InputEventMouseMotion:
		var current_pos = get_viewport().get_mouse_position()
		if last_position_visible.distance_to(current_pos) > mouse_tolerance:
			last_position_visible = get_viewport().get_mouse_position()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#endregion

func _ready() -> void:
	hidden_cursor_ready()
	load_graphics_settings()
	load_audio_settings()
	load_controls_settings()
	play_animation_by_group("only_on_launch", "game_start_player")

func _process(_delta):
	hidden_cursor_process(_delta)
	
func _input(event):
	hidden_cursor_input(event)
