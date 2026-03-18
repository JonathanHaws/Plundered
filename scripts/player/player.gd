extends CharacterBody3D
@export var kill_y: float = -5
@export var anim: AnimationPlayer 
@export var speed := 3.0
@export var speed_multiplier := 1.0
@export var jump_height := 4.0
@export var sprint_multiplier := 2.0
@export var sens := 0.002
@export var cam : Camera3D
@export var gravity := 9.8
@export var jump_buffer_time: float = .2
@export var coyote_time: float = .25
@export var fov_lerp := Node
@export var audio_spawner: Node
var jump_buffer = 0;
var falling = coyote_time;
var was_on_floor : bool = true
var ignore_first_was_on_floor : bool = true
var pitch := 0.0
var mouse_delta := Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_delta += event.relative

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

func _free_movement(_d):
	if Input.is_action_just_pressed("jump"): jump_buffer = jump_buffer_time;
	elif jump_buffer > 0: jump_buffer -= _d	
		
	var movement_vector = Vector3(
		int(Input.is_action_pressed("keyboard_right")) - int(Input.is_action_pressed("keyboard_left")),0,
		int(Input.is_action_pressed("keyboard_back")) - int(Input.is_action_pressed("keyboard_forward"))
		)
		
	if not is_on_floor(): velocity.y -= gravity * _d
		
	falling = 0.0 if is_on_floor() else falling + _d	
		
	if falling < coyote_time and jump_buffer > 0:
		falling = coyote_time + 1;
		if audio_spawner: audio_spawner.play("Jump")
		velocity.y = jump_height 
	
	var current_speed = speed * speed_multiplier
	if Input.is_action_pressed("sprint"):
		current_speed *= sprint_multiplier

	var dir = movement_vector.rotated(Vector3.UP, cam.global_rotation.y).normalized()
	velocity.x = dir.x * current_speed
	velocity.z = dir.z * current_speed
	move_and_slide()
	
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
		if audio_spawner: 
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
	
	#print(anim.current_animation)
	
	if anim.current_animation in ["Steer", "God"]:
		_move_camera()
	
	if anim.current_animation in ["Idle", "Run", "Walk", "Jump"]:
		_free_movement(_delta)
		_move_camera()
	
	if global_position.y < kill_y or is_player_ship_sunk():
		anim.play("Death")
		
