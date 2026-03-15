extends Node ## For dynamically spawning and triggering existing audio nodes (as a parent)
func play_random_child() -> void:
	var nodes = get_children()
	if nodes.size() == 0: return
	var idx = randi() % nodes.size()
	var node = nodes[idx]
	if node is AudioStreamPlayer:
		node.pitch_scale = randf_range(PITCH_MULTIPLIER - PITCH_VARIANCE, PITCH_MULTIPLIER + PITCH_VARIANCE)
		node.volume_db = linear_to_db((db_to_linear(node.volume_db) * VOLUME_MULTIPLIER) + randf_range(-VOLUME_VARIANCE, VOLUME_VARIANCE))
		node.play()

@export_subgroup("Spawning") ## Does not change audio already added to the tree just for when initially spawned)
@export var SOUNDS: Array[AudioStream] = []
@export var VOLUME_MULTIPLIERS: Array[float] = [] ## Easily multiplier for getting balance of audio right
@export var GROUPS: Array[String] ## Groups that dynamically spawned players are added to
@export var AVOID_STACKING_GROUPS: Array[String] = [] ## If any players already exists with one of these groups, dont spawn new sound
@export var AUDIO_BUS: String = "SFX"
@export var ADD_TO_ROOT: bool = false ## Added as a sibling to globals... So When calling change scene to file it doesnt get removed 
@export var VOLUME_MULTIPLIER: float = 1.0 
@export var PITCH_MULTIPLIER: float = 1.0 
@export var VOLUME_VARIANCE: float = 0.0
@export var PITCH_VARIANCE: float = 0.0
func get_sound_index_from_string(sound_name: String) -> int:
	for i in range(SOUNDS.size()):
		var audio_name = SOUNDS[i].resource_path.get_file().get_basename().to_lower()
		if audio_name == sound_name.to_lower(): return i
	return -1
func get_sound_index_from_array(sound_array: Array) -> int:
	if sound_array.size() == 0: return -1
	var chosen_sound = sound_array[randi() % sound_array.size()]
	return get_sound_index(chosen_sound)
func get_sound_index(sound: Variant) -> int:
	if sound == null: 
		if SOUNDS.size() == 0: return -1
		else: return 0
	elif sound is int: return sound
	elif sound is Array: return get_sound_index_from_array(sound)
	elif sound is String: return get_sound_index_from_string(sound)
	elif sound is AudioStream: return SOUNDS.find(sound)
	return -1	
func spawn_sound(sound: Variant = null) -> AudioStreamPlayer:

	var sound_index = get_sound_index(sound)
	if sound_index < 0 or sound_index >= SOUNDS.size(): return null
	
	#print('test')
	
	if ONLY_SPAWN_IF_VISIBLE and not ONLY_SPAWN_IF_VISIBLE.is_visible_in_tree():
		return
	
	
	for group_name in AVOID_STACKING_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			if node.is_inside_tree(): return null  # skip spawning
	
	var final_sound = SOUNDS[sound_index]
	var base_volume = 1.0
	if sound_index < VOLUME_MULTIPLIERS.size():
		base_volume = VOLUME_MULTIPLIERS[sound_index]
	
	var player = AudioStreamPlayer.new()
	player.stream = final_sound
	player.pitch_scale = randf_range(PITCH_MULTIPLIER - PITCH_VARIANCE, PITCH_MULTIPLIER + PITCH_VARIANCE)
	#print(base_volume)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	player.volume_db = linear_to_db(base_volume * (VOLUME_MULTIPLIER + randf_range(-VOLUME_VARIANCE, VOLUME_VARIANCE))) 
	player.bus = AUDIO_BUS
	player.connect("tree_entered", Callable(player, "play"))
	player.connect("finished", Callable(player, "queue_free"))
	
	for group_name in GROUPS:
		if group_name != "":
			player.add_to_group(group_name)
	
	if ADD_TO_ROOT:
		var tree := Engine.get_main_loop()
		tree.get_root().call_deferred("add_child", player)
	else:
		add_child.call_deferred(player)
	return player

@export_group("Ready") 
@export var SPAWN_ON_LOAD: bool = false ## Makes first sound autoplay on load
@export var DESTORY_GROUPS: Array[String] ## Groups that are destroyed in ready to avoid choatic audial overlap when switching scenes
@export_group("Tween Bus Volumes") 
@export var BUS_NAMES: Array[String] = [] ## Specifies which buses to change the volume of when this node is loaded in ready
@export var TWEEN_TO_MULTIPLIERS: Array[float] = [] ## Specifies the desired percentage.
@export var TWEEN_DURATION: Array[float] = [.75] ## Specifies how long 
func tween_bus(bus_name: String, target_multiplier: float, duration_seconds: float) -> void:
	Config.tween_bus_volume(bus_name, target_multiplier, duration_seconds)

@export_group("Menu") 
## Menu sounds shouldnt play unless the menu is visible. Use this to specify the 'menu
@export var ONLY_SPAWN_IF_VISIBLE: Node
@export var HOVER_SOUND: String = "Menu_Hover"
@export var PRESSED_SOUND: String = "Menu_Hover"
@export var FOCUS_SOUND: String = "Menu_Hover"
@export var HOVERED_GROUP: String = "menu_hovered_sound"
@export var PRESSED_GROUP: String = "menu_pressed_sound"
@export var FOCUS_ENTERED_GROUP: String = "menu_focus_sound"
func _connect_group_signal(group_name: String, signal_name: String, sound_name: String) -> void:
	#print('test')
	if group_name == "": return
	if sound_name == "": return
	for node in get_tree().get_nodes_in_group(group_name): 		
		if node.has_signal(signal_name):
			node.connect(signal_name, Callable(self, "spawn_sound").bind(sound_name))

func _ready() -> void:
	
	if SPAWN_ON_LOAD: spawn_sound.call_deferred()
	
	for group_name in DESTORY_GROUPS: 
		for node in get_tree().get_nodes_in_group(group_name): node.queue_free()

	for i in range(BUS_NAMES.size()):
		tween_bus(BUS_NAMES[i], TWEEN_TO_MULTIPLIERS[i], TWEEN_DURATION[i])

	await get_tree().create_timer(0.1,true,false, true).timeout ## No menu sounds right off the bat
	_connect_group_signal(HOVERED_GROUP, "mouse_entered", HOVER_SOUND)
	_connect_group_signal(PRESSED_GROUP, "pressed", PRESSED_SOUND)
	_connect_group_signal(FOCUS_ENTERED_GROUP, "focus_entered", HOVER_SOUND)
	
