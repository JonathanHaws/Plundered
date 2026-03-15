extends RigidBody3D
@export var player_group: String = "player"
@export var player_animator_group: String = "player_anim"
func _on_enter_steer(body):
	if body.is_in_group(player_group):
		in_range_of_steering = true
func _on_exit_steer(body):
	if body.is_in_group(player_group):
		in_range_of_steering = false
var player: CharacterBody3D
var player_anim: AnimationPlayer
var in_range_of_steering: bool = false

@export var is_docked: bool = true
@export var speed: float = 23
@export var steer: float = 3
@export var gravity: float = 9.8
@export var buoyancy := 1.0
@export var water_drag := 0.01
@export var water_angular_drag := 0.05
var submerged: bool = false

func _ready():
	add_to_group("boats")
	$SteerArea.body_entered.connect(_on_enter_steer)	# signal
	$SteerArea.body_exited.connect(_on_exit_steer)	# signal
	player = get_tree().get_first_node_in_group(player_group)	
	player_anim = get_tree().get_first_node_in_group(player_animator_group)
	
	#dynamically add probes to collison shape
	var shape = $CollisionShape3D.shape
	if shape is BoxShape3D:
		var extents = shape.extents  # half-widths of the box
		var y_offset = -extents.y  # slightly below hull
		var positions = [
			Vector3(-extents.x, y_offset, extents.z),  # Front-Left
			Vector3(extents.x, y_offset, extents.z),   # Front-Right
			Vector3(-extents.x, y_offset, -extents.z), # Back-Left
			Vector3(extents.x, y_offset, -extents.z)   # Back-Right
		]
		for pos in positions:
			var probe = Node3D.new()
			probe.position = pos
			#simply for seeing the probe location and degbugging
			#var mesh_instance = MeshInstance3D.new()  # create mesh
			#mesh_instance.mesh = SphereMesh.new()    # simple sphere
			#mesh_instance.scale = Vector3.ONE * 0.1  # small size
			#probe.add_child(mesh_instance)
			$CollisionShape3D.add_child(probe)
	
	

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if submerged:
		state.linear_velocity *=  1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag 

func _physics_process(_delta):

	#print(player_in)

	submerged = false
	for probe in $CollisionShape3D.get_children():
		## var water_level = get_tree().get_nodes_in_group("ocean")[0].get_water_level(p.global_position)
		var water_level = 0
		var depth = water_level - probe.global_position.y
		#print('testing probe')
		if depth > 0:
			submerged = true
			apply_force(Vector3.UP * buoyancy * depth, probe.global_position - global_transform.origin)
	
	if Input.is_action_just_pressed("interact"):
		if player_anim.current_animation == "Steer": 
			player_anim.play("Idle")
			player.speed_multiplier = 1
		elif in_range_of_steering and Input.is_action_just_pressed("interact"): 
			player_anim.play("Steer")
			player.speed_multiplier = 0
			#print('test')

	if player_anim.current_animation != "Steer": return
	var movement_vector = Vector3(
		int(Input.is_action_pressed("keyboard_right")) - int(Input.is_action_pressed("keyboard_left")),0,
		int(Input.is_action_pressed("keyboard_back")) - int(Input.is_action_pressed("keyboard_forward"))
		)
		
	player.global_transform = $SteerPosition.global_transform
	
	apply_torque_impulse(Vector3.UP * steer * -movement_vector.x)
	apply_central_force(global_transform.basis.z.normalized() * movement_vector.z * speed)

	player.global_transform = $SteerPosition.global_transform



	#var forward = -global_transform.basis.z.normalized()
	#var t = transform
	#t.origin += t.basis.z * movement_vector.z * 10 * _delta  # forward/back speed
	#transform = t
#
	#print(movement_vector)
#
	## left/right rotation
	#rotate_y(-movement_vector.x * 0.5 * _delta)  # rotate at fixed rate
	
	
	
