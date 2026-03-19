extends AnimationPlayer
var cooldown
var spawner

@export_group("Base Difficulty")	
@export var min_ships: float = 2.0
@export var breathing_time: float = 7
@export var random_breathing_time: float = 2
@export var spawn_distance: float = 50.0
@export var random_spawn_distance: float = 20.0
@export var speed: float = 400.0
@export var steer: float = 80.0
@export var cannon_cooldown: float = 8.0
@export var cannon_random_cooldown: float = 4.0
@export var cannon_random_aim: Vector2 = Vector2(5, 5)

@export_group("Auto Progress Difficulty")
@export var auto_progress: bool = true
@export var curve_base_time: float = 100
@export var curve_min_ships: Curve
@export var curve_breathing_time: Curve
@export var curve_random_breathing_time: Curve
@export var curve_spawn_distance: Curve
@export var curve_random_spawn_distance: Curve
@export var curve_speed: Curve
@export var curve_steer: Curve
@export var curve_cannon_cooldown: Curve
@export var curve_cannon_random_cooldown: Curve
@export var curve_cannon_random_aim: Curve
var min_separation: float = 25.0 # Spawns boats fruther if overlapping

var progress_time : float = 0.0
func get_curve_value_at_time(curve: Curve) -> float:
	var t = clamp(progress_time / curve_base_time, 0.0, 1.0)
	return curve.sample(t)

func _ready() -> void:
	cooldown = breathing_time + (randf() * random_breathing_time)
	spawner = get_parent()
	#print('test')

func get_random_backward_direction(node:Node3D) -> Vector3:
	# Returns a random direction in the half circle behind where the players currently looking
	var forward = -node.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var dir = forward.rotated(Vector3.UP, randf_range(-PI/2.0, PI/2.0) + PI)
	dir.y = 0
	return dir.normalized()

func _process(_delta):
	
	#print(cooldown)
	
	if auto_progress:
		
		#print(round(progress_time), " ", min_ships)
		progress_time += _delta
		
		if curve_min_ships:
			min_ships = get_curve_value_at_time(curve_min_ships)
		if curve_breathing_time:
			breathing_time = get_curve_value_at_time(curve_breathing_time)
		if curve_random_breathing_time:
			random_breathing_time = get_curve_value_at_time(curve_random_breathing_time)
		if curve_spawn_distance:
			spawn_distance = get_curve_value_at_time(curve_spawn_distance)
		if curve_random_spawn_distance:
			random_spawn_distance = get_curve_value_at_time(curve_random_spawn_distance)
		
		if curve_speed:
			speed = get_curve_value_at_time(curve_speed)
		if curve_steer:
			steer = get_curve_value_at_time(curve_steer)
			

	#print(boat_count)
	var boat_count = get_tree().get_nodes_in_group("boats").size()
	if boat_count > floor(min_ships): return
	
	cooldown -= _delta
	if cooldown > 0: return 
	cooldown = breathing_time + (randf() * random_breathing_time)
	var cam = get_viewport().get_camera_3d()

	var distance: float = spawn_distance + (randf() * random_spawn_distance)
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
	#print('spawning new boat out of view at:', round(spawn_position))
	
	spawner.global_position = spawn_position
	spawner.rotation.y = randf_range(0.0, TAU)
	spawner.global_position.y = 0.0
	var boat = spawner.spawn()
	boat.speed = speed
	boat.steer = steer
	boat.cannon_cooldown = cannon_cooldown
	boat.cannon_random_cooldown = cannon_random_cooldown
	boat.cannon_random_aim = cannon_random_aim
	#print(boat.name) ## Add stat buffs as tiem goes on

	cooldown = breathing_time + (randf() * random_breathing_time)
