extends RigidBody3D

@export_group('Stats')
@export var health: float = 1000.0
@export var speed: float = 1000
@export var steer: float = 100

@export var cannon_cooldown_min: float = 8.0 ## Minimum duration enemy ships will wait between shots
@export var cannon_cooldown_max: float = 12.0 ## Add this to the mimum duration and its maximum duration
@export var cannon_aim: Vector2 = Vector2(5, 5) ## How inaccurate Enemies shots will be. 
func set_health_and_max_health(value: float) -> void:
	health = value
	$HitArea.HEALTH = health
	$HitArea.MAX_HEALTH = health

@export var sigil: int = 0
var sigils: Array = ["none", "beer", "doliphin", "shark", "turtle", "whale", "jolly_roger"]

@export_group('Physics')
#@export var is_docked: bool = true add if wanting sails to be own control
@export var sink_free_y: float = -50.0
@export var gravity: float = 9.8
@export var buoyancy: float = 3.1
@export var water_drag: float = 0.015
@export var air_drag: float = 0.01
@export var water_angular_drag: float = 0.04
@export var air_angular_drag: float = 0.01
@export var speed_multiplier: float = 0.8 ## BANDAID FINAL TWEAKS
@export var steer_multiplier: float = 0.8 ## BANDAID FINAL TWEAKS
var submerged: bool = false
var sunk: bool = false

@export_group('Player')
@export var player_ship_name: String = "PlayerShip"
@export var player_group: String = "player"
@export var player_animator_group: String = "player_anim"
@export var leak_per_second: float = 20.0  ## HP lost per second when not at max health
var player: CharacterBody3D
var player_anim: AnimationPlayer

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if submerged:
		state.linear_velocity *= 1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag
	else:
		state.linear_velocity *= 1 - air_drag
		state.angular_velocity *= 1 - air_angular_drag

func on_ship_sunk() -> void:
	#print("sunk")
	sunk = true
	remove_from_group("boats")
	if name != player_ship_name:
		Save.data["bounty"] = Save.data.get("bounty", 0) + 100
		Save.save_game()
		$Audio/Bounty.play()
		
		
		for i in 5:
			var loot = $HitArea/LootSpawner.spawn()	# spawn loot
			if loot:
				
				#$RamArea.add_immune_group("loot_hitarea")
				
				loot.get_node("HitShape").add_immune_group("enemy_ram_area")
				loot.apply_random_force()
				#print(loot.global_position)


func impact(strength: float) -> void:
	var impulse = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized() * strength
	var offset = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1))
	apply_impulse(impulse, offset)
	
func apply_boat_controls(forward: float, right: float, _delta: float) -> void:
	#print("moving boat ", name, " at a speed of ", speed * forward, " and steering ", right * steer)
	
	var forward_direction = -global_transform.basis.z
	forward_direction.y = 0 # avoid flying ships going to vahalla... only apply force x / y
	forward_direction = forward_direction.normalized()
	
	apply_central_force(forward_direction * forward * (speed * speed_multiplier) * _delta)
	apply_torque_impulse(Vector3.UP * right * (steer * steer_multiplier) * _delta)
	
func _ready():
	
	# replaces static meshses with animatable bodies as they carry momentu
	
	set_health_and_max_health(health)
	
	if name == player_ship_name: sigil = 0
	
	add_to_group('boats')
	add_to_group(name)
	player = get_tree().get_first_node_in_group(player_group)	
	player_anim = get_tree().get_first_node_in_group(player_animator_group)
	$HitArea.add_immune_group(name + "CannonBall")
	
	if name == player_ship_name:
		Save.data["bounty"] = 0
		Save.save_game()
	
	if name != player_ship_name:
		$Leaks.queue_free()
		$Targets.queue_free()
		$RamArea.add_to_group("enemy_ram_area")
	
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
			
			#simply for seeing the probe locations and degbugging
			#var mesh_instance = MeshInstance3D.new()
			#mesh_instance.mesh = SphereMesh.new() 
			#mesh_instance.scale = Vector3.ONE
			#probe.add_child(mesh_instance)
	
	# Simply for seeing target locations and debugging
	#for target in $Targets.get_children():
		#var mesh = MeshInstance3D.new()
		#mesh.mesh = BoxMesh.new()
		#mesh.scale = Vector3.ONE * 20
		#target.add_child(mesh)
	

	
	$RamArea.add_to_group(name + "_ram_area")
	$HitArea.add_immune_group(name + "_ram_area")
	
	for mesh in $Ship.get_children():
		for child in mesh.get_children():
			if child is StaticBody3D:
				var new_body = AnimatableBody3D.new()
				new_body.sync_to_physics = false
				new_body.transform = child.transform
				
				for c in child.get_children():
					child.remove_child(c)
					new_body.add_child(c)
				
				mesh.call_deferred("add_child", new_body)
				child.call_deferred("queue_free")
	
	
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
	if name == player_ship_name: # Only produce leaks for player ship
	
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
	
