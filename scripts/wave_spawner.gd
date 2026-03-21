extends AnimationPlayer
@onready var spawner = $SceneSpawner

@export_group("Spawning")
@export var min_separation: float = 25.0 
@export var distance_min: float = 100.0
@export var distance_max: float = 110.0
var sigils: Array = ["none", "beer", "doliphin", "shark", "turtle", "whale", "jolly_roger"]
func set_distance_min_and_max(
	_new_distance_min := distance_min,
	_new_distance_max := distance_max
) -> void:
	distance_min = _new_distance_min
	distance_max = _new_distance_max
func set_sigil_pool(new_sigils: Array[String]) -> void:
	sigils = new_sigils.duplicate()

@export_group("Boat")
@export var speed: float = 400
@export var steer: float = 80
@export var health: float = 3000
func set_speed_steer_and_health(
	_speed := speed,
	_steer := steer,
	_health := health
) -> void:
	speed = _speed
	steer = _steer
	health = _health

@export_group("Cannons")
@export var cannon_cooldown_min: float = 8.0
@export var cannon_cooldown_max: float = 12.0
@export var cannon_aim: Vector2 = Vector2(5, 5)
func set_cannon_cooldown_and_aim(
	_new_cooldown_min := cannon_cooldown_min,
	_new_cooldown_max := cannon_cooldown_max,
	_new_aim := cannon_aim
	) -> void:
		cannon_cooldown_min = _new_cooldown_min
		cannon_cooldown_max = _new_cooldown_max
		cannon_aim = _new_aim

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
	_distance_min := distance_min,
	_distance_max := distance_max,
	_speed := speed,
	_steer := steer,
	_health := health,
	_cannon_cooldown_min := cannon_cooldown_min,
	_cannon_cooldown_max := cannon_cooldown_max,
	_cannon_aim := cannon_aim
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

	spawner.global_position = spawn_position
	spawner.rotation.y = randf_range(0.0, TAU)
	spawner.global_position.y = 0.0

	var boat = spawner.spawn()
	boat.speed = _speed
	boat.steer = _steer
	boat.cannon_cooldown_min = _cannon_cooldown_min
	boat.cannon_cooldown_max= _cannon_cooldown_max
	boat.cannon_aim = _cannon_aim
	boat.sigil = sigils[randi() % sigils.size()]
	boat.set_health_and_max_health(_health)
	
	print("Boat:",
		" speed=", _speed,
		" steer=", _steer,
		" health=", _health,
		" cooldown_min=", _cannon_cooldown_min,
		" cooldown_max=", _cannon_cooldown_max,
		" aim=", _cannon_aim,
		" sigil=", boat.sigil
	)
	
	
	
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
	play(wave_name)
	#print('starting next wave: ', wave_name)
	
@export_group("Auto Progress Difficulty")
@export var auto_progress: bool = false
@export var curve_base_time: float = 100
@export var curve_spawn_distance: Curve
@export var curve_random_spawn_distance: Curve
@export var curve_speed: Curve
@export var curve_steer: Curve
@export var curve_cannon_cooldown: Curve
@export var curve_cannon_random_cooldown: Curve
@export var curve_cannon_random_aim: Curve
var progress_time : float = 0.0
func get_curve_value_at_time(curve: Curve) -> float:
	var t = clamp(progress_time / curve_base_time, 0.0, 1.0)
	return curve.sample(t)

func _process(_delta):

	poll_next_wave()
