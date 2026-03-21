extends AnimationPlayer
@onready var spawner: Node3D = $SceneSpawner
var boat_presets = {
	"beer": {
		"speed": 100,
		"steer": 10,
		"health": 1000,
		"cannon_cooldown_min": 10.0,
		"cannon_cooldown_max": 15.0,
		"cannon_aim": Vector2(10, 10),
		"distance_min": 300.0,
		"distance_max": 400.0,
	},
	"turtle": {
		"speed": 300,
		"steer": 30,
		"health": 2000,
		"cannon_cooldown_min": 7.0,
		"cannon_cooldown_max": 11.0,
		"cannon_aim": Vector2(8, 8),
		"distance_min": 300.0,
		"distance_max": 400.0,
		"sigils": ["turtle"],
		},
	"doliphin": {
		"speed": 1500,
		"steer": 150,
		"health": 3000,
		"cannon_cooldown_min": 6.0,
		"cannon_cooldown_max": 10.0,
		"cannon_aim": Vector2(6, 6),
		"distance_min": 300.0,
		"distance_max": 400.0,
		"sigils": ["doliphin"],
		},
	"whale": {
		"speed": 500,
		"steer": 50,
		"health": 7000,
		"cannon_cooldown_min": 6.0,
		"cannon_cooldown_max": 10.0,
		"cannon_aim": Vector2(6, 6),
		"distance_min": 300.0,
		"distance_max": 400.0,
		"sigils": ["whale"],
		},
	"shark": {
		"speed": 1000,
		"steer": 50,
		"health": 3000,
		"cannon_cooldown_min": 1.0,
		"cannon_cooldown_max": 3.0,
		"cannon_aim": Vector2(5, 5),
		"distance_min": 300.0,
		"distance_max": 400.0,
		"sigils": ["shark"],
		},

}

@export var min_separation: float = 25.0

func spawn_preset_boat(preset_name: String) -> void:
	if not boat_presets.has(preset_name):
		return
	
	var preset = boat_presets[preset_name]
	spawn_boat_out_of_view(
		preset.get("distance_min", 300.0),
		preset.get("distance_max", 400.0),
		preset.get("speed", 400),
		preset.get("steer", 80),
		preset.get("health", 3000),
		preset.get("cannon_cooldown_min", 8.0),
		preset.get("cannon_cooldown_max", 12.0),
		preset.get("cannon_aim", Vector2(5, 5)),
		preset.get("sigils", [preset_name])
	)

@export_group("Spawning")
func get_random_backward_direction(node:Node3D) -> Vector3:
	# Returns a random direction in the half circle behind where the players currently looking
	var forward = -node.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var dir = forward.rotated(Vector3.UP, randf_range(-PI/2.0, PI/2.0) + PI)
	dir.y = 0
	return dir.normalized()
func spawn_boat_out_of_view(
	_distance_min: float,
	_distance_max: float,
	_speed: float,
	_steer: float,
	_health: int,
	_cannon_cooldown_min: float,
	_cannon_cooldown_max: float,
	_cannon_aim: Vector2,
	_sigils: Array
	) -> void:
	var cam = get_viewport().get_camera_3d()

	var distance: float = randf_range(_distance_min, _distance_max)
	var spawn_position = cam.global_position + (get_random_backward_direction(cam) * distance)

	var clear := false
	while not clear:
		clear = true
		for boat in get_tree().get_nodes_in_group("boats"):
			if boat.global_position.distance_to(spawn_position) < min_separation:
				distance += min_separation
				spawn_position = cam.global_position + (get_random_backward_direction(cam) * distance)
				clear = false
				break

	#await get_tree().physics_frame
	#await get_tree().physics_frame
	spawner.global_position = spawn_position
	spawner.rotation.y = randf_range(0.0, TAU)
	spawner.global_position.y = 0.0

	var boat = spawner.spawn()
	boat.speed = _speed
	boat.steer = _steer
	boat.cannon_cooldown_min = _cannon_cooldown_min
	boat.cannon_cooldown_max= _cannon_cooldown_max
	boat.cannon_aim = _cannon_aim
	
	var sigil_name: String = _sigils[randi() % _sigils.size()]
	var idx: int = boat.sigils.find(sigil_name)
	if idx != -1: boat.sigil = idx
	
	boat.set_health_and_max_health(_health)
	
	#print("Boat:",
		#" speed=", _speed,
		#" steer=", _steer,
		#" health=", _health,
		#" cooldown_min=", _cannon_cooldown_min,
		#" cooldown_max=", _cannon_cooldown_max,
		#" aim=", _cannon_aim,
		#" sigil=", boat.sigil,
	#)
	
@export_group("Waves")	
@export var next_wave_pool: Array = []
func is_wave_cleared() -> bool:
	return get_tree().get_nodes_in_group("boats").size() <= 1
func set_next_wave_pool(waves: Array = ["wave_easy_1"]) -> void:
	next_wave_pool = waves.duplicate()
func poll_next_wave() -> void:
	if is_playing(): return  # don't start a new wave if one is running
	if not is_wave_cleared(): return
	if next_wave_pool.is_empty(): return
	
	var wave_name = next_wave_pool[randi() % next_wave_pool.size()]
	if has_animation(wave_name):
		play(wave_name)
		#print('starting next wave: ', wave_name)

func _process(_delta):

	poll_next_wave()

	
#@export_group("Auto Progress Difficulty")
#@export var auto_progress: bool = false
#@export var curve_base_time: float = 100
#@export var curve_spawn_distance: Curve
#@export var curve_random_spawn_distance: Curve
#@export var curve_speed: Curve
#@export var curve_steer: Curve
#@export var curve_cannon_cooldown: Curve
#@export var curve_cannon_random_cooldown: Curve
#@export var curve_cannon_random_aim: Curve
#var progress_time : float = 0.0
#func get_curve_value_at_time(curve: Curve) -> float:
	#var t = clamp(progress_time / curve_base_time, 0.0, 1.0)
	#return curve.sample(t)
