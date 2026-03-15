## Used for particles, projectiles, and other dynamically spawned scenes
## Use top level for scene transforms to avoid them following parents 
extends Node
@export_group("Scenes") 
@export var scenes: Array[PackedScene]
@export var add_to_groups: Array[String] = []
@export var scene_to_spawn: int = 0 ## Specifies which scene to spawn 
@export var random_scene: bool = false ## Overrides 'scene_to_spawn'
@export var add_to_scene_root: bool = false ## Makes spawned scene a child of the scene root instead of this node. Useful when particles want to spawn other particles) Still starts with this nodes initial transform though
@export var add_to_root: bool = false ## Makes it so scene spawned will still exist even if scene changes
func get_scene_to_spawn(scene_variant: Variant = scene_to_spawn) -> PackedScene:
	if scenes.size() == 0: return null 
	if scene_variant != -1: # call method track requesting a specific scene to be spawned
		if scene_variant is int and scene_variant >= 0 and scene_variant < scenes.size():
			return scenes[scene_variant]
	if random_scene: return scenes[randi() % scenes.size()]
	if scene_to_spawn >= 0 and scene_to_spawn < scenes.size():
		return scenes[scene_to_spawn]
	if scenes.size() == 1: # fallback if only one scene exists
		return scenes[0]
	return null 

@export_group("Transform 3D") 
@export var target: Node3D = null ## Specifies a target to orient towards with spawned scenes initial transform
@export var projectile_speed: float = 10.0
@export var projectile_gravity: float = 0.0	
func get_orientation_towards_position_3d(target_position: Vector3, position: Vector3) -> Basis:
	var to_target = target_position - position
	var distance = to_target.length()
	var time = distance / projectile_speed
	var target_velocity: Vector3
	
	if projectile_gravity > 0: # arc
		target_velocity = to_target / time
		target_velocity.y += 0.5 * projectile_gravity * time
	else: # straight
		target_velocity = to_target / time
	
	return Basis.looking_at(target_velocity.normalized(), Vector3.UP)

@export_group("Waves") 
## Stop progress until all enemies are killed by making wave animation end with 
## a call method track on the animation player itself with a stop(). 
## when all enemies are killed play will be called
@export var wave_animation_player: AnimationPlayer 
func _check_wave_end():
	if not is_inside_tree(): return
	if get_tree().get_nodes_in_group("wave_spawned").is_empty():
		#print("All enemies killed spawning new wave")
		wave_animation_player.play()	# advance wave

func spawn_towards_target(scene_count: int = 1, delay: float = 0.0, weight: Vector3 = Vector3(1,1,1)) -> void:
	if target == null: return  
	for i in range(scene_count):
		#print('spawning')
		var scene = spawn()
		var target_orientation = get_orientation_towards_position_3d(target.global_position, self.global_position).get_euler()
		var original_orientation = scene.global_transform.basis.get_euler()
		
		var lerp_pitch = lerp(original_orientation.x, target_orientation.x, weight.x)
		var lerp_yaw = lerp(original_orientation.y, target_orientation.y, weight.y)
		var lerp_roll = lerp(original_orientation.z, target_orientation.z, weight.z)
			
		scene.global_transform.basis = Basis.from_euler(Vector3(lerp_pitch, lerp_yaw, lerp_roll))
		if scene.has_method("set_velocity_from_orientation"): scene.set_velocity_from_orientation()
		
		if delay > 0: await get_tree().create_timer(delay).timeout

func spawn_along_curve(curve_group: String, scene_count: int = 1, delay: float = 0) -> void:
	var path: Path3D = null
	var curve: Curve3D = null
	for n in get_tree().get_nodes_in_group(curve_group):
		if n is Path3D and n.curve != null:
			path = n
			curve = n.curve
			break
	if path == null or curve == null: return  

	var percent_interval = float(1.0 / scene_count)
	
	for i in range(scene_count + 1):
		var local_pos = curve.sample_baked((percent_interval * i) * curve.get_baked_length())
		var world_pos = path.to_global(local_pos)
		var orientation = get_orientation_towards_position_3d(world_pos, self.global_position)
		var transform = Transform3D(orientation, self.global_position)
		
		#print(path.name, " ", (percent_interval * i), " ", transform.basis.get_euler()) 
		
		var scene = spawn()
		scene.global_transform = transform
		if scene.has_method("set_velocity_from_orientation"): scene.set_velocity_from_orientation()
		
		if delay > 0: await get_tree().create_timer(delay).timeout

func spawn_multiple(count: int = 1, delay: float = 0.0) -> void:
	for i in range(count):
		spawn()
		if delay > 0: await get_tree().create_timer(delay).timeout

func spawn_towards_camera_group(group: String = "player_camera",  weight: Vector3 = Vector3(1,1,1)) -> void:
	for c in get_tree().get_nodes_in_group(group):
		#print(pitch, yaw)
		var scene  = spawn()
		if  scene and  scene is Node3D:
			var original_orientation = scene.global_transform.basis.get_euler()
			var aim: Vector3 = -c.global_transform.basis.z * 1000000.0
			var camera_target_orientation = Transform3D(Basis.looking_at(scene.global_position + aim, Vector3.UP), scene.global_position).basis.get_euler()
			
			var lerp_pitch: float = lerp(original_orientation.x, camera_target_orientation.x, weight.x)
			var lerp_yaw: float = lerp(original_orientation.y, camera_target_orientation.y, weight.y)
			var lerp_roll: float = lerp(original_orientation.z, camera_target_orientation.z, weight.z)
			
			scene.global_transform.basis = Basis.from_euler(Vector3(lerp_pitch, lerp_yaw, lerp_roll))
			if scene.has_method("set_velocity_from_orientation"): scene.set_velocity_from_orientation()
		return
	
func spawn(scene_variant: Variant = -1) -> Node:
	
	var scene_to_instantiate = get_scene_to_spawn(scene_variant)
	#print(scene_to_instantiate.resource_path.get_file())
	
	if scene_to_instantiate == null: return
	var scene = scene_to_instantiate.instantiate()
	
	for group in add_to_groups: scene.add_to_group(group)
	
	if add_to_root:
		get_tree().root.add_child(scene)
	elif add_to_scene_root:
		var root = get_tree().get_current_scene()
		if root: root.add_child(scene)	
	else:
		add_child(scene)	
	
	if scene is Node3D: scene.global_transform = self.global_transform
	
	if wave_animation_player:
		scene.add_to_group("wave_spawned")
		scene.tree_exited.connect(_check_wave_end)
	
	#if "material_override" in scene: #for making shader unique for every particle might be a bug
		#var mat = scene.material_override
		#if mat:
			#print('duplicated')
			#mat = mat.duplicate()
			#mat.shader = scene.material_override.shader
			#scene.material_override = mat
		
	#if scene is Node3D and scene.material_override: #for making shader unique for every particle might be a bug
		#scene.material_override = scene.material_override.duplicate()
		
	return scene
