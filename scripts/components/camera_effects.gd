extends Node ## Node for camera impact effects like shake / slow motion 
## Given as Engine.time_scale can not be relied on for a delta of 0. get_tree().paused must be used.
const pause_menu_group: String = "pause_menu" ## Used to not accidentally interfere and pause the game. 
@export var shake = 0.0
@export var default_decay_rate = 40.0
@export var noise_frequency: float = 2.2
@export var max_shake = 13.0
@export var TREMOR_STRENGTH: float = 1.0
@export var TARGET_GROUP: String = "player"
var noise := FastNoiseLite.new()
var shake_offset := Vector3.ZERO
var decay_rate = default_decay_rate

@export var shake_presets := {
	"player_attack": { "strength": 4.0, "slow_motion_duration": .1,  "slow_motion_speed": 0.0},
	"player_blocked":{ "strength": 1.0, "slow_motion_duration": .4,  "slow_motion_speed": 0.0},
	"player_heal":   { "strength": 2.0, "slow_motion_duration": .1,  "slow_motion_speed": 0.0},
	"player_shoot":  { "strength": 1.0, "slow_motion_duration": .1,  "slow_motion_speed": 0.0},
	"player_hurt":   { "strength": 2.5, "slow_motion_duration": .1,  "slow_motion_speed": 0.0},
	"player_kill":   { "strength": 3.5, "slow_motion_duration": .22,  "slow_motion_speed": 0.0},
	"player_death":  { "strength": 0.0, "slow_motion_duration": 1, "slow_motion_speed": 0.2},
	"boss_death":    { "strength": 1.0, "slow_motion_duration": 2.0, "slow_motion_speed": 0.7},
	"enemy_death":   { "strength": 1.0, "slow_motion_duration": 0.3, "slow_motion_speed": 0.2},
	"small":  		 { "strength": 3.0, "slow_motion_duration": 0.13, "slow_motion_speed": 0.0},
	"big": 			 { "strength": 6.0, "slow_motion_duration": .5,  "slow_motion_speed": 0.5},
	"boss_scream":   { "continious_tremor_strength": .8, "continuious_tremor_duration": 1.5 }
}

 ## Used so that if a new slow motion impact enters the tree the slower impact gets priority
class slow_motion_impact:
	extends Node
	var speed: float
	var duration: float
	
	func get_lowest_slow_motion_speed(exclude_self: bool = false) -> float:
		var lowest_speed = 1.0
		for node in get_tree().get_nodes_in_group("slow_motion_impact"):
			if exclude_self and node == self: continue
			lowest_speed = min(lowest_speed, node.speed)
		#print(lowest_speed)
		return lowest_speed

	func _init(_speed: float, _duration: float):
		speed = _speed
		duration = _duration
		add_to_group("slow_motion_impact")	
	
	func _ready():
		var slow_motion_speed = get_lowest_slow_motion_speed(false)
		
		if slow_motion_speed > 0: 
			Engine.time_scale = slow_motion_speed	
		else:
			get_tree().paused = true
			
		await get_tree().create_timer(duration, true, false, true).timeout
		queue_free()
		
	func _exit_tree() -> void:
		var slow_motion_speed = get_lowest_slow_motion_speed(true)
		if slow_motion_speed > 0:
			
			Engine.time_scale = slow_motion_speed	
			
			for n in get_tree().get_nodes_in_group("pause_menu"): if n.visible: return
			get_tree().paused = false

func slow_motion(duration: float, speed: float = 0.0) -> void: 
	if not is_inside_tree(): return
	var impact_instance = slow_motion_impact.new(speed, duration) # renamed
	add_child(impact_instance)
	
func tremor(scale: float = 1.0) ->void:
	shake += scale

func continious_tremor(strength: float, duration: float = 1.0) -> void:
	decay_rate = 0
	shake = strength
	await get_tree().create_timer(duration, true, false, true).timeout
	decay_rate = default_decay_rate

func impact(preset_name: String = "", camera_shake: float = .2, slow_motion_duration: float = .2, slow_motion_speed: float = 0):
	if preset_name != "" and shake_presets.has(preset_name):
		var preset = shake_presets[preset_name]
		#print(preset_name)
		if preset.has("strength"): 
			shake +=  preset.strength
		if preset.has("decay"):
			decay_rate = preset.decay
		if preset.has("slow_motion_duration"):
			var duration = preset.get("slow_motion_duration", .1)
			var impact_speed = preset.get("slow_motion_speed", 0)
			slow_motion(duration, impact_speed)
		if preset.has("continious_tremor_strength") and preset.has("continuious_tremor_duration"):
			var strength = preset.continious_tremor_strength
			var duration = preset.continuious_tremor_duration
			continious_tremor(strength, duration)	
		return
	tremor(camera_shake)	
	slow_motion(slow_motion_duration, slow_motion_speed)
	
func _ready():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = noise_frequency

func _physics_process(delta):
	var current_camera := get_viewport().get_camera_3d()
	if !current_camera: return
	current_camera.rotation_degrees -= shake_offset # Remove previous frame's shake
	if shake > 0.0:
		shake -= decay_rate * delta
		shake = max(shake, 0.0)
		var time = Engine.get_physics_frames()
		var shake_x = noise.get_noise_2d(time * 0.05, 0.0)
		var shake_y = noise.get_noise_2d(time * 0.05, 1000.0) 
		var shake_z = noise.get_noise_2d(time * 0.05, 2000.0) 
		shake_offset.x = clamp(shake_x * shake, -max_shake, max_shake)
		shake_offset.y = clamp(shake_y * shake, -max_shake, max_shake)
		shake_offset.z = clamp(shake_z * shake, -max_shake, max_shake)
		current_camera.rotation_degrees += shake_offset
		
func _on_body_entered(body) -> void:
	if body.is_in_group(TARGET_GROUP):
		#print('registering')
		tremor(TREMOR_STRENGTH)
