extends RigidBody3D
#@export var is_docked: bool = true add if wanting sails to be own control
@export var is_players_boat: bool = false
@export var player_group: String = "player"
@export var player_animator_group: String = "player_anim"
@export var sink_free_y: float = -50.0

@export var leak_per_second: float = 10.0  ## HP lost per second when not at max health

@export var gravity: float = 9.8
@export var buoyancy: float = 3.1
@export var water_drag: float = 0.02
@export var air_drag: float = 0.01
@export var water_angular_drag: float = 0.05
@export var air_angular_drag: float = 0.01

var player: CharacterBody3D
var player_anim: AnimationPlayer
var in_range_of_steering: bool = false
var submerged: bool = false
var sunk: bool = false

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if submerged:
		state.linear_velocity *= 1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag
	else:
		state.linear_velocity *= 1 - air_drag
		state.angular_velocity *= 1 - air_angular_drag

func on_ship_sunk() -> void:
	#print("sunk")
	remove_from_group("boats")
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
	
	add_to_group('boats')
	add_to_group(name)
	player = get_tree().get_first_node_in_group(player_group)	
	player_anim = get_tree().get_first_node_in_group(player_animator_group)
	$HitArea.add_immune_group(name + "CannonBall")
	
	if is_players_boat:
		Save.data["bounty"] = 0
		Save.save_game()
	
	if name == "PlayerShip":
		for target in $Targets.get_children():
			target.add_to_group("PlayerShipTargets")
	
	#print(name)
	
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
			$CollisionShape3D.add_child(probe)
			
			#simply for seeing the probe location and degbugging
			#var mesh_instance = MeshInstance3D.new()
			#mesh_instance.mesh = SphereMesh.new() 
			#mesh_instance.scale = Vector3.ONE
			#probe.add_child(mesh_instance)
	
	# replaces static meshses with animatable bodies as they carry momentu
	for mesh in $Ship.get_children():
		for child in mesh.get_children():
			if child is StaticBody3D:
				#print('test')
				var new_body = AnimatableBody3D.new()
				new_body.sync_to_physics = false
				new_body.transform = child.transform
				
				for c in child.get_children():
					child.remove_child(c)
					new_body.add_child(c)
				
				mesh.add_child(new_body)
				child.queue_free()
	
func _process(_delta):

	if sunk and global_position.y < sink_free_y:
		#print('ship queued free')
		queue_free()

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
	
	#print($HitArea.HEALTH)
	if name == "PlayerShip": # Only produce leaks for player ship
	
		if  get_tree().get_nodes_in_group("leaks").size() > 0:
			$HitArea.HEALTH -= leak_per_second * _delta
			#print("leaking", $HitArea.HEALTH)
	
		if $HitArea.HEALTH < $HitArea.MAX_HEALTH:
			
			var max_leaks = int(($HitArea.MAX_HEALTH - $HitArea.HEALTH) / 150)
			var current_leaks = get_tree().get_nodes_in_group("leaks").size()
			if current_leaks < max_leaks:
				var leaks = $Leaks.get_children()
				var candidates = []
				for l in leaks:
					if l.get_child_count() == 0: candidates.append(l)
				if candidates.size() > 0: candidates.pick_random().call("spawn")
	
