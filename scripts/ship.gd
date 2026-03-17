extends RigidBody3D
#@export var is_docked: bool = true add if wanting sails to be own control
@export var is_players_boat: bool = false
@export var player_group: String = "player"
@export var player_animator_group: String = "player_anim"
@export var sink_free_y: float = -50.0
@export var speed: float = 1200
@export var steer: float = 160

@export var ai_speed: float = 400
@export var ai_steer: float = 120

@export var gravity: float = 9.8
@export var buoyancy := 1.0
@export var water_drag := 0.01
@export var water_angular_drag := 0.05
var player: CharacterBody3D
var player_anim: AnimationPlayer
var in_range_of_steering: bool = false
var submerged: bool = false
var sunk: bool = false
var steering: bool = false
func _on_enter_steer(body):
	if body.is_in_group(player_group):
		in_range_of_steering = true
func _on_exit_steer(body):
	if body.is_in_group(player_group):
		in_range_of_steering = false

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if submerged:
		state.linear_velocity *=  1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag 

func on_ship_sunk() -> void:
	#print("sunk")
	Save.data["bounty"] = Save.data.get("bounty", 0) + 100
	Save.save_game()
	sunk = true
	
func impact(strength: float) -> void:
	var impulse = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized() * strength
	var offset = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1))
	apply_impulse(impulse, offset)
	
func apply_boat_controls(control_speed: float, control_steer: float, _delta: float) -> void:
	apply_central_force(-global_transform.basis.z.normalized() * control_speed * _delta)
	apply_torque_impulse(Vector3.UP * control_steer * _delta)
	
func _ready():
	
	if is_players_boat:
		Save.data["bounty"] = 0
		Save.save_game()
	
	if name == "PlayerShip":
		for target in $Targets.get_children():
			target.add_to_group("PlayerShipTargets")
	
	add_to_group('boats')
	add_to_group(name)
	$HitArea.add_immune_group(name + "CannonBall")
	#print(name)
	
	$Ship/SteerArea.body_entered.connect(_on_enter_steer)
	$Ship/SteerArea.body_exited.connect(_on_exit_steer)
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
	
func _process(_delta):

	if sunk and global_position.y < sink_free_y:
		#print('ship queued free')
		queue_free()

	#print($HitArea.HEALTH)

	submerged = false
	for probe in $CollisionShape3D.get_children():
		## var water_level = get_tree().get_nodes_in_group("ocean")[0].get_water_level(p.global_position)
		var water_level = 0
		var depth = water_level - probe.global_position.y
		#print('testing probe')
		if depth > 0:
			submerged = true
			if not sunk:
				apply_force(Vector3.UP * buoyancy * depth, probe.global_position - global_transform.origin)
	
	if name == "PlayerShip":
		if $HitArea.HEALTH < $HitArea.MAX_HEALTH:
			var max_leaks = int(($HitArea.MAX_HEALTH - $HitArea.HEALTH) / 150)
			var current_leaks = get_tree().get_nodes_in_group("leaks").size()
			if current_leaks < max_leaks:
				var leaks = $Leaks.get_children()
				var candidates = []
				for l in leaks:
					if l.get_child_count() == 0: candidates.append(l)
				if candidates.size() > 0: candidates.pick_random().call("spawn")
	
	
	
	
	if Input.is_action_just_pressed("interact"):
		if steering:
			steering = false
			player_anim.play("Idle")
			player.speed_multiplier = 1
			player.mouse_delta = Vector2.ZERO
		elif in_range_of_steering:
			steering = true
			player.reset_camera()
			player.global_transform = $Ship/SteerSpot.global_transform
			player_anim.play("Steer")
			player.speed_multiplier = 0

				#print('test')

	ai_steering(_delta)
	player_steering(_delta)

func ai_steering(_delta):
	if is_players_boat: return
	
	var targets = get_tree().get_nodes_in_group("PlayerShipTargets")
	if targets.size() == 0: return

	var forward = -global_transform.basis.z.normalized()
	var best_score = -INF
	var best_target = null

	# add scoring to keep ship in optimal distance away

	for t in targets:
		var to_target = (t.global_position - global_position).normalized()
		var dist = global_position.distance_to(t.global_position)
		var alignment = forward.dot(to_target)  # 1 = straight ahead, -1 = behind
		var score = alignment / dist  # high alignment + close distance
		if score > best_score:
			best_score = score
			best_target = t

	if not best_target: return

	# turn shortest way to target
	var dir = (best_target.global_position - global_position).normalized()
	var angle = atan2(dir.x, dir.z) - atan2(forward.x, forward.z)
	angle = wrapf(angle, -PI, PI)

	apply_boat_controls(ai_speed * 0.2, ai_steer * sign(angle), _delta)
	
func player_steering(_delta) -> void:
	if not steering: return
	var movement_vector = Vector3(
		int(Input.is_action_pressed("keyboard_right")) - int(Input.is_action_pressed("keyboard_left")),0,
		int(Input.is_action_pressed("keyboard_forward")) - int(Input.is_action_pressed("keyboard_back"))
		)
	player.global_position = $Ship/SteerSpot.global_position
	
	apply_boat_controls(speed * movement_vector.z, -steer * movement_vector.x, _delta)
	
	
