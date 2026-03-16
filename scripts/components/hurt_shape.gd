extends Area3D
@export_group("Damage")
@export var damage: float = 10.0
@export var damage_spread: float = 0 ## Determines subtle randomness in attack damage
@export var damage_multiplier: float = 1 ## Value that can be animated by animation players 
@export var disabled: bool = false
@export var cooldown: float = 0.2 
@export var linger_tick: float = 1.0
@export var linger: bool = false
@export var hit_shape: Area3D ## Avoid lingering by automatocally freeing this hurtbox when this hitshape dies
@export var hit_anim: String = "HURT" ## Name of the animation to play when something is hit
@export var kill_anim: String = "KILL" ## Name of animation to play when something is killed
@export var hit_animation_player: AnimationPlayer ## Animation to be played when something is hit by this hurt shape
var overlapping_areas: Dictionary = {}
signal hurt_something

@export_group("Blocking")
@export var parryable: bool = false ## Animate property to specify window
@export var parry_anim: String = "PARRY"
@export var blocked_anim_player: AnimationPlayer
@export var block_groups: Array[String] = ["player_blockshape", "enemy_blockshape"]
func blocked(_block_time: float = 0.0) -> void:
	if blocked_anim_player and blocked_anim_player.has_animation(parry_anim):
		if blocked_anim_player.current_animation != parry_anim:
			blocked_anim_player.play(parry_anim)

@export_group("Save") ## For upgradable damage that needs to be persisten / update
@export var enable_save: bool = false
@export var save_key: String = ""
func _exit_tree() -> void:
	if not enable_save: return
	Save.data[save_key] = damage
	Save.save_game()
func _on_save_data_updated() -> void:
	#if Save.data[save_key] != damage: #upgrade animation 
	damage = Save.data[save_key]
	damage_multiplier = 1.0
	#print(damage)
	
func save_ready() -> void:
	if not enable_save: return
	
	if save_key == "": save_key = Save.get_unique_key(self, "damage")
	if Save.data.has(save_key): damage = Save.data[save_key]
	else: Save.data[save_key] = damage

	Save.connect("save_data_updated", _on_save_data_updated)

func hurt(area: Area3D) -> void:
	#print("hurt ", area.name)
	
	if disabled: return
	emit_signal("hurt_something")
	await get_tree().physics_frame # Ensure both the regular hit_shape AND block_shape is in 'overlapping areas;
	
	# Check if one of overlapping areas is in block group... Then call hit on it instead instead of parameter area...
	var target_to_hit := area
	for group in block_groups:
		for node in overlapping_areas:
			if node.is_in_group(group):
				target_to_hit = node
				#print(node.name)
				break
	
	#print("Cooldown remaining:", overlapping_areas[area]["cooldown"].is_stopped())
	if area not in overlapping_areas: return
	if not overlapping_areas[area]["cooldown"].is_stopped(): return
	if !"hit" in area: return
	
	if target_to_hit.hit(self, int(damage + randf_range(-damage_spread, damage_spread)) * damage_multiplier):
		overlapping_areas[area]["cooldown"].start()
		overlapping_areas[area]["linger"].start() 
		
		if hit_animation_player:
			if "HEALTH" in target_to_hit and target_to_hit.HEALTH <= 0:
				if hit_animation_player.has_animation(kill_anim): hit_animation_player.play(kill_anim)
			else:
				hit_animation_player.play(hit_anim)
			
func _on_area_entered(area: Area3D) -> void:
	
	var blocking_area: bool = false # Verify in group
	for group in block_groups:
		if area.is_in_group(group):
			blocking_area = true
			break
	if blocking_area: return
	
	if area not in overlapping_areas:
		var cooldown_timer = Timer.new()
		cooldown_timer.one_shot = true
		cooldown_timer.wait_time = cooldown
		add_child(cooldown_timer)
		#cooldown_timer.add_to_group("memory_leak_check")

		var linger_timer = Timer.new()
		linger_timer.wait_time = linger_tick
		add_child(linger_timer)
		if linger: linger_timer.timeout.connect(func() -> void: hurt(area))
		#linger_timer.add_to_group("memory_leak_check")

		overlapping_areas[area] = { "cooldown": cooldown_timer, "linger": linger_timer }

	hurt(area)

func _on_area_exited(area: Area3D) -> void:
	if area in overlapping_areas: # Clean up potential memory leak
		for t in overlapping_areas[area].values(): t.queue_free() 
		overlapping_areas.erase(area)

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	save_ready()
	
	if hit_shape and hit_shape.has_signal("DIED"):
		hit_shape.DIED.connect(queue_free)
	
func on_ship_hit() -> void:
	print('hit')
	

#func _process(_delta: float) -> void:
	#print("Timers alive:", get_tree().get_nodes_in_group("memory_leak_check").size())
