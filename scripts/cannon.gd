extends Node
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
var in_range_of_aiming: bool = false
var player: CharacterBody3D
var player_anim: AnimationPlayer
func _on_enter_aim(body):
	if body.is_in_group(player_group):
		in_range_of_aiming = true
func _on_exit_aim(body):
	if body.is_in_group(player_group):
		in_range_of_aiming= false

func _ready() -> void:

	$AimArea.body_entered.connect(_on_enter_aim)	
	$AimArea.body_exited.connect(_on_exit_aim)	
	
	player = get_tree().get_first_node_in_group(player_group)	
	player_anim = get_tree().get_first_node_in_group(player_animator_group)
	
	scene_spawner.add_dynamic_group(get_parent().name)
	#print(get_parent().name)
	
func _physics_process(_delta: float) -> void:
	
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
		var yaw: float = horizontal_mesh.rotation_degrees.y - event.relative.x * yaw_sensitivity
		var pitch: float = vertical_mesh.rotation_degrees.x - event.relative.y * pitch_sensitivity
		
		horizontal_mesh.rotation_degrees.y = clamp(yaw, min_yaw, max_yaw)
		vertical_mesh.rotation_degrees.x = clamp(pitch, min_pitch, max_pitch)
			
