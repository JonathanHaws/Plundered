extends Node3D
@export_group("Controls")
@export var yaw_sensitivity: float = 0.1
@export var pitch_sensitivity: float = 0.1
@export var min_pitch: float = -10
@export var max_pitch: float = 40
@export var min_yaw: float = -70
@export var max_yaw: float = 70
var in_range_of_aiming: bool = false
var aiming: bool = false
func clamp_aim() -> void:
	#print(horizontal_mesh.rotation_degrees.y, vertical_mesh.rotation_degrees.x)
	stand.rotation_degrees = Vector3(0, clamp(stand.rotation_degrees.y, min_yaw, max_yaw), 0)
	barrel.rotation_degrees = Vector3(clamp(barrel.rotation_degrees.x, min_pitch, max_pitch), 0, 0)
func _on_enter_aim(body):
	if body.is_in_group(player_group):
		in_range_of_aiming = true
func _on_exit_aim(body):
	if body.is_in_group(player_group):
		in_range_of_aiming= false

@export_group("References")
@export var boat: RigidBody3D
@export var player_group: String = "player"
@export var player_animator_group: String = "player_anim"
@onready var stand: Node3D = $cannon
@onready var barrel: Node3D = $cannon/Barrel
@onready var scene_spawner: Node3D = $cannon/Barrel/Node3D
var player: CharacterBody3D
var player_anim: AnimationPlayer

@export_group("Ai")
func get_random_cooldown() -> float:
	return randf_range(get_parent().cannon_cooldown_min, get_parent().cannon_cooldown_max)
var ai_aim_offset = Vector3(0, 2.0, 0)
var ai_cooldown_remaining: float

func _ready() -> void:
	ai_cooldown_remaining = get_random_cooldown()
	
	if not boat: boat = get_parent()
	$AimArea.body_entered.connect(_on_enter_aim)	
	$AimArea.body_exited.connect(_on_exit_aim)	
	player = get_tree().get_first_node_in_group(player_group)	
	player_anim = get_tree().get_first_node_in_group(player_animator_group)
	scene_spawner.add_dynamic_group(get_parent().name + 'CannonBall')
	#print(get_parent().name)
	
func _process(_delta: float) -> void:
		
	ai_aim(_delta)	
	aim()	
		
	if boat.name == "PlayerShip": # Can Only Aim Your Ship
		
		if Input.is_action_just_pressed("interact") and not aiming and in_range_of_aiming: 
			aiming = true
			$AimSound.play()
			$cannon/Barrel/Camera3D.current = true
			player_anim.play("Aim")
			player.speed_multiplier = 0
			player.global_position = $AimSpot.global_position
			#print('test')
			
		elif Input.is_action_just_pressed("stop_interacting") and aiming:
			aiming = false
			player_anim.play("Idle")
			player.speed_multiplier = 1
			player.mouse_delta = Vector2.ZERO
			player.global_position = $AimSpot.global_position
			$cannon/Barrel/Camera3D.current = false
		
func _input(event):
	if not aiming: return
	if event is InputEventMouseMotion:
		stand.rotation_degrees.y += -event.relative.x * yaw_sensitivity
		barrel.rotation_degrees.x += -event.relative.y * pitch_sensitivity
		clamp_aim()

func is_player_ship_sunk() -> bool:
	for b in get_tree().get_nodes_in_group("boats"):
		if b.name == "PlayerShip" and not b.sunk:
			return false
	return true
	
func ai_aim(delta: float) -> void:
	var parent = get_parent()
	if parent.name == "PlayerShip": return
	if get_parent().sunk: return
	if is_player_ship_sunk(): return
	
	var player_ship = get_tree().get_first_node_in_group("PlayerShip")
	if player_ship == null: return

	if ai_cooldown_remaining > 0:
		ai_cooldown_remaining -= delta
	if ai_cooldown_remaining > 0: return
	
	var original_stand_rotation = stand.rotation_degrees.y
	var original_barrel_rotation = barrel.rotation_degrees.x
	
	var target = player_ship.global_position + ai_aim_offset
	var to_target = target - stand.global_position
	var dist = Vector2(to_target.x, to_target.z).length()
	var y = to_target.y
	var v = 30.0
	var g = 9.8
	var disc = v*v*v*v - g*(g*dist*dist + 2.0*y*v*v)
	if disc <= 0 or dist == 0: return
	var t = dist / (v * cos(atan((v*v - sqrt(disc)) / (g*dist))))
	var aim_pos = target + player_ship.linear_velocity * t + Vector3(0, 0.5*g*t*t, 0)

	stand.look_at(aim_pos, Vector3.UP)
	stand.rotation_degrees.y += randf_range(-get_parent().cannon_aim.y, get_parent().cannon_aim.y)
	var optimal_stand_rotation = stand.rotation_degrees.y
	clamp_aim()

	barrel.look_at(aim_pos, Vector3.UP)
	barrel.rotation_degrees.x += randf_range(-get_parent().cannon_aim.x, get_parent().cannon_aim.x)
	var optimal_barrel_rotation = barrel.rotation_degrees.x
	clamp_aim()

	if stand.rotation_degrees.y != optimal_stand_rotation or barrel.rotation_degrees.x != optimal_barrel_rotation:
		stand.rotation_degrees.y = original_stand_rotation
		barrel.rotation_degrees.x = original_barrel_rotation
		return  # aim was clamped, skip firing

	$AnimationPlayer.play("fire")
	ai_cooldown_remaining = get_random_cooldown()
	
func aim() -> void:
	
	if not aiming: return
	if Input.is_action_just_pressed("shoot"):
		player.global_position = $AimSpot.global_position
		
		$AnimationPlayer.speed_scale = 1.0 / boat.cannon_cooldown_min
		$AnimationPlayer.play("fire")	
