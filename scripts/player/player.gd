extends CharacterBody3D
@export var kill_y: float = -5
@export var anim: AnimationPlayer 

@export var speed_multiplier := 1.0
@export var jump_height := 4.0
@export var sens := 0.002
@export var cam : Camera3D
@export var gravity := 9.8
@export var jump_buffer_time: float = .2
@export var coyote_time: float = .25
@export var fov_lerp := Node
@export var audio_spawner: Node
var jump_buffer = 0;
var air_time = coyote_time;
var was_on_floor : bool = true
var ignore_first_was_on_floor : bool = true
var pitch := 0.0
var mouse_delta := Vector2.ZERO
var in_combat_music: bool = false

@export var speed := 1.9
@export var sprint_multiplier := 2.0
@export var max_speed := 2.0
@export var ground_drag := 0.1
@export var air_drag := 0.1
@onready var last_global_position: Vector3 = global_position
@onready var ship_momentum: Vector3 = Vector3.ZERO

@export_group("StepUp")
@export var STEP_UP_RAY: RayCast3D
@onready var step_up_y: float = STEP_UP_RAY.position.y
@onready var step_up_z: float = STEP_UP_RAY.position.z
func try_step_up() -> void:
	
	var dir := -Vector3(velocity.x, 0, velocity.z) 
	if dir.length() > 0.01:
		dir = dir.normalized() * step_up_z
		STEP_UP_RAY.global_position = global_position + (dir) 
		STEP_UP_RAY.position.y = step_up_y

	if not STEP_UP_RAY: return
	if not STEP_UP_RAY.is_colliding(): return
	if velocity.y > 1: return # Jumping ignore
	

	var hit_y: float = STEP_UP_RAY.get_collision_point().y
	var body_y: float = global_position.y
	if hit_y <= body_y: return
	
	# Make step up not work if its too steep an angle
	var hit_normal: Vector3 = STEP_UP_RAY.get_collision_normal()
	var up: Vector3 = Vector3.UP
	var angle: float = acos(clamp(hit_normal.dot(up), -1.0, 1.0))
	if angle > floor_max_angle: return

	# Return if would be in collision
	var new_pos: Vector3 = Vector3(global_position.x, hit_y, global_position.z)
	var params := PhysicsTestMotionParameters3D.new()
	params.from = global_transform
	params.motion = new_pos - global_position
	if PhysicsServer3D.body_test_motion(get_rid(), params): return
	
	#play_land_effects()
	air_time = 0
	velocity.y = 0
	global_position.y = hit_y


func _input(event):
	if event is InputEventMouseMotion:
		mouse_delta += event.relative

func get_movement_vector() -> Vector3:
	return Vector3(
		int(Input.is_action_pressed("keyboard_right")) - int(Input.is_action_pressed("keyboard_left")), 0,
		int(Input.is_action_pressed("keyboard_forward")) - int(Input.is_action_pressed("keyboard_back"))
	)

func get_flat_forward_vector(vector: Vector3) -> Vector3:
	var dir = (-cam.global_transform.basis.z * vector.z + cam.global_transform.basis.x * vector.x)
	dir.y = 0
	return dir.normalized()


func _move_camera():
	rotate_y(-mouse_delta.x * sens)
	pitch = clamp(pitch - mouse_delta.y * sens, -1.5, 1.5)
	cam.rotation.x = pitch
	mouse_delta = Vector2.ZERO

func is_player_ship_sunk() -> bool:
	for b in get_tree().get_nodes_in_group("boats"):
		if b.name == "PlayerShip" and not b.sunk:
			return false
	return true

func get_nearest_enemy_distance() -> float:
	var min_distance := INF
	for b in get_tree().get_nodes_in_group("boats"):
		if b.name != "PlayerShip" and not b.sunk:
			var distance := global_position.distance_to(b.global_position)
			if distance < min_distance:
				min_distance = distance
	return min_distance

func is_wave_cleared() -> bool:
	var count := 0
	for b in get_tree().get_nodes_in_group("boats"):
		if not b.sunk:	count += 1
	return count <= 1

func is_cannon_balls() -> bool:
	return get_tree().get_nodes_in_group("cannon_balls").size() > 0

func _free_movement(_d):
	
	try_step_up()
	
	if Input.is_action_just_pressed("jump"): jump_buffer = jump_buffer_time;
	elif jump_buffer > 0: jump_buffer -= _d	
		
	var movement_vector = get_movement_vector()
		
	if not is_on_floor(): velocity.y -= gravity * _d
		
	air_time = 0.0 if is_on_floor() else air_time + _d	
		
	if air_time < coyote_time and jump_buffer > 0:
		air_time = coyote_time + 1;
		if audio_spawner: audio_spawner.play("Jump")
		
		#print(ship_momentum)
		#velocity.x += ship_momentum.x 
		#velocity.z += ship_momentum.z
		velocity.y = jump_height 
	
	var current_speed = speed * speed_multiplier
	if Input.is_action_pressed("sprint"):
		current_speed *= sprint_multiplier

	

	var dir = get_flat_forward_vector(get_movement_vector())
	var drag = ground_drag if is_on_floor() else air_drag
	velocity.x *= 1.0 - drag
	velocity.z *= 1.0 - drag
	
	# Apply input movement
	velocity.x += dir.x * current_speed 
	velocity.z += dir.z * current_speed 
	
	
	
	ship_momentum = (global_position - last_global_position)
	#print(ship_momentum)
	last_global_position = global_position
	move_and_slide()
	
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	if horizontal_vel.length() > max_speed:
		horizontal_vel = horizontal_vel.normalized() * max_speed
		velocity.x = horizontal_vel.x
		velocity.z = horizontal_vel.z
	
	
	
	if movement_vector.length() == 0:
		fov_lerp.target_fov = 80 # Idle
	else:
		if Input.is_action_pressed("sprint"): fov_lerp.target_fov = 90 # Sprint
		else: fov_lerp.target_fov = 85 # Walk
	
	var on_floor_now = is_on_floor()
	
	if ignore_first_was_on_floor and not was_on_floor: #bandaid super annoying bug 
		was_on_floor = true
		ignore_first_was_on_floor = false
		
	if not was_on_floor and on_floor_now:
		if audio_spawner and air_time > 0.15: 
			audio_spawner.play("Land")	
	was_on_floor = on_floor_now
	
	
	if is_on_floor():
		if movement_vector.length() > 0:
			if Input.is_action_pressed("sprint"):
				anim.play("Run")
			else:
				anim.play("Walk")
		else:
			anim.play("Idle")
	else:
		anim.play("Jump")
		
func _physics_process(_delta):
	
	print(global_position)
	
	if not anim.current_animation in ["Death"]:
		var dist := get_nearest_enemy_distance()

		if dist < 75.0 or (is_cannon_balls() and dist < 100.0):
			if not in_combat_music:
				in_combat_music = true
				var t := create_tween().set_parallel(true)
				t.tween_property($Audio/CalmMusic, "volume_db", -40.0, 5.0)
				$Audio/CombatMusic.volume_db = -40.0
				$Audio/CombatMusic.play()
				t.tween_property($Audio/CombatMusic, "volume_db", 0.0, 5.0)
		else:
			if in_combat_music and is_wave_cleared():
				in_combat_music = false
				var t := create_tween().set_parallel(true)
				t.tween_property($Audio/CombatMusic, "volume_db", -40.0, 6.0)
				$Audio/CalmMusic.volume_db = -40.0
				$Audio/CalmMusic.play()
				t.tween_property($Audio/CalmMusic, "volume_db", 0.0, 6.0)
		
	if anim.current_animation in ["Steer", "God"]:
		_move_camera()
	
	if anim.current_animation in ["Idle", "Run", "Walk", "Jump"]:
		_free_movement(_delta)
		_move_camera()
	
	if anim.current_animation in "God": return
	
	if anim.current_animation != "Death" and (global_position.y < kill_y or is_player_ship_sunk()):
		anim.play("Death")
		
		
	
