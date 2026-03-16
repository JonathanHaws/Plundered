extends Node3D
@export var player_group: String = "player"
@export var player_animator_group: String = "player_anim"
@export var scene_spawner: Node
@export var horizontal_mesh: Node3D
@export var vertical_mesh: Node3D
@export var yaw_sensitivity: float = 0.1
@export var pitch_sensitivity: float = 0.1

@export var min_pitch: float = -40
@export var max_pitch: float = 40
@export var min_yaw: float = -90
@export var max_yaw: float = 90
func clamp_aim() -> void:
	#print(horizontal_mesh.rotation_degrees.y, vertical_mesh.rotation_degrees.x)
	horizontal_mesh.rotation_degrees = Vector3(0, clamp(horizontal_mesh.rotation_degrees.y, min_yaw, max_yaw), 0)
	vertical_mesh.rotation_degrees = Vector3(clamp(vertical_mesh.rotation_degrees.x, min_pitch, max_pitch), 0, 0)

var in_range_of_aiming: bool = false
var player: CharacterBody3D
var player_anim: AnimationPlayer
func _on_enter_aim(body):
	if body.is_in_group(player_group):
		in_range_of_aiming = true
func _on_exit_aim(body):
	if body.is_in_group(player_group):
		in_range_of_aiming= false

@export var ai_cooldown: float = 2.0
@export var ai_random_cooldown: float = 2.0
@export var ai_random_offset = Vector3(11, 11, 11)
@export var ai_random_aim: Vector2 = Vector2(5, 5)
var ai_cooldown_remaining: float = 0.0
var ai_aim_offset = Vector3(0, 2.0, 0)
func ai_aim(delta: float) -> void:
	var parent = get_parent()
	if parent.name == "PlayerShip": return
	var player_ship = get_tree().get_first_node_in_group("PlayerShip")
	if player_ship == null: return

	if ai_cooldown_remaining > 0:
		ai_cooldown_remaining -= delta
	if ai_cooldown_remaining > 0: return
	
	var h_y_orig = horizontal_mesh.rotation_degrees.y
	var v_x_orig = vertical_mesh.rotation_degrees.x
	
	var target = player_ship.global_position + ai_aim_offset
	var to_target = target - horizontal_mesh.global_position
	var dist = Vector2(to_target.x, to_target.z).length()
	var y = to_target.y
	var v = 30.0
	var g = 9.8
	var disc = v*v*v*v - g*(g*dist*dist + 2.0*y*v*v)
	if disc <= 0 or dist == 0: return
	var t = dist / (v * cos(atan((v*v - sqrt(disc)) / (g*dist))))
	var aim_pos = target + player_ship.linear_velocity * t + Vector3(0, 0.5*g*t*t, 0)

	horizontal_mesh.look_at(aim_pos, Vector3.UP)
	horizontal_mesh.rotation_degrees.y += randf_range(-ai_random_aim.y, ai_random_aim.y)
	var h_y_before = horizontal_mesh.rotation_degrees.y
	clamp_aim()

	vertical_mesh.look_at(aim_pos, Vector3.UP)
	vertical_mesh.rotation_degrees.x += randf_range(-ai_random_aim.x, ai_random_aim.x)
	var v_x_before = vertical_mesh.rotation_degrees.x
	clamp_aim()

	if horizontal_mesh.rotation_degrees.y != h_y_before or vertical_mesh.rotation_degrees.x != v_x_before:
		horizontal_mesh.rotation_degrees.y = h_y_orig
		vertical_mesh.rotation_degrees.x = v_x_orig
		return  # aim was clamped, skip firing


	$AnimationPlayer.play("fire")
	ai_cooldown_remaining = ai_cooldown + randf_range(0, ai_random_cooldown)


func _ready() -> void:

	$AimArea.body_entered.connect(_on_enter_aim)	
	$AimArea.body_exited.connect(_on_exit_aim)	
	
	player = get_tree().get_first_node_in_group(player_group)	
	player_anim = get_tree().get_first_node_in_group(player_animator_group)
	
	scene_spawner.add_dynamic_group(get_parent().name + '_ball')
	#print(get_parent().name)
	
func _physics_process(_delta: float) -> void:
	
	ai_aim(_delta)
			

	if in_range_of_aiming:
		if Input.is_action_just_pressed("interact"):
			if player_anim.current_animation == "Aim": 
				player_anim.play("Idle")
				player.speed_multiplier = 1
				player.mouse_delta = Vector2.ZERO
			elif in_range_of_aiming: 
				player_anim.play("Aim")
				player.speed_multiplier = 0
				#print('test')
			
	if player_anim.current_animation != "Aim": return
	if not in_range_of_aiming: return
	
	player.global_transform = $AimPosition.global_transform
	
	if Input.is_action_just_pressed("jump"):
		#print('fire')
		$AnimationPlayer.play("fire")
		
func _input(event):
	if player_anim.current_animation != "Aim": return
	if not in_range_of_aiming: return
	
	if event is InputEventMouseMotion:
		horizontal_mesh.rotation_degrees.y += -event.relative.x * yaw_sensitivity
		vertical_mesh.rotation_degrees.x += -event.relative.y * pitch_sensitivity
		clamp_aim()
			
