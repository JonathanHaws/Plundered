extends Area3D
signal DIED
signal HURT
signal HEAL
@export_group("Health")
@export var IMMUNE_GROUPS: Array[String] = [] ## Groups of hurtboxes in which this scene is immune to
@export var HEALTH :float = 500.0
@export var MAX_HEALTH	:float = 500.0
@export var INVINCIBILITY_COOLDOWN: float = 0.05 ## After object gets hit how long they are invincible
@export var DISABLED: bool = false 
var last_hurt_shape: Area3D = null ## most recent hurt_shape to damage this shape
var invincibility_timer: Timer
func add_immune_group(group_name: String) -> void:
	if not group_name in IMMUNE_GROUPS:
		IMMUNE_GROUPS.append(group_name)

@export_group("Persistence Between Scenes")
@export var PERSISTENT_HEALTH: bool = true ## Most entities you want queue freed if health < 0 in ready... except player sometimes (Only works if Root Is Specified)
@export var ROOT: Node ## Root of scene that will be freed if health is less then 0 when scene loaded in ready
@export var HEALTH_KEY: String = "" ## What save key to store health persistently between scenes being loaded / unloaded. If left empty will just use unique node path

@export_group("Damage Reaction") ## For Body / Child Nodes which have to reposition themselves. Such as Needed positional synchronization between attacker / attacked on animations, Hurt Particles, etc.
@export var TELEPORT_NODES_TO_HIT: Array[Node3D] = [] 
@export var HURT_ANIMATION_PLAYER: AnimationPlayer
@export var DEATH_ANIMATION_PLAYER: AnimationPlayer
@export var HEAL_ANIMATION_PLAYER: AnimationPlayer
@export var HURT_ANIM: String = "HURT"
@export var DEATH_ANIM: String = "DEATH"
@export var HEAL_ANIM: String = "HEAL"
@export var DAMAGE_NUMBERS: PackedScene
func show_damage(damage_amount: int) -> void:
	var number = DAMAGE_NUMBERS.instantiate()
	number.get_node("Node2D/Label").text = str(int(damage_amount))
	get_tree().current_scene.add_child(number)
	number.position = get_viewport().get_camera_3d().unproject_position(self.global_position) - Vector2(0, 140.0)

@export_group("Respawn") ## For configuring exactly how persistent save data is handled
@export var RESPAWN_WHEN_DEATHS_INCREMENT: bool = true ## Makes it so entitiy resets save data when player dies
@export var RESPAWN_WHEN_RESTS_INCREMENT: bool = true ## Makes it so entitiy resets save data when player rests
@export var DEATHS_KEY: String = "deaths" ## What save key keeps track of players deaths
@export var RESTS_KEY: String = "rests" ## What save key keeps track of players rests 
@export var DEATH_COUNT_KEY: String = "" ## What save key keeps track of this entities deaths
@export var REST_COUNT_KEY: String = "" ## What save key keeps track of this entities rests 
func _load_respawn(counter_key: String, total_key: String) -> void: ## Checks in ready for if its updated. If so resets health
	
	var total = Save.data.get(total_key, 0) 
	if Save.data.has(counter_key):
		if Save.data[counter_key] <= total:
			Save.data[counter_key] = total + 1
			if Save.data.has(HEALTH_KEY): Save.data.erase(HEALTH_KEY)
	else:
		Save.data[counter_key] = total + 1

@export_group("Save Max Health")
@export var UPGRADABLE_MAX_HEALTH: bool = false
@export var MAX_HEALTH_KEY: String = ""
func _check_max_health() -> void: # When save data is updated and fires a singal checks if max health has changed
	#var difference = Save.data[MAX_HEALTH_KEY] - MAX_HEALTH Upgrade animation
	#if difference <= 0: return
	#if ANIMATION_PLAYER and UPGRADE_ANIMATION != "":
		#ANIMATION_PLAYER.play(UPGRADE_ANIMATION)
	MAX_HEALTH = Save.data[MAX_HEALTH_KEY]
func _load_max_health() -> void:
	
	if not UPGRADABLE_MAX_HEALTH: return # Keep default max health for entity
	if not Save.data.has(MAX_HEALTH_KEY): Save.data[MAX_HEALTH_KEY] = MAX_HEALTH
	MAX_HEALTH = Save.data[MAX_HEALTH_KEY]
	Save.connect("save_data_updated", Callable(self, "_check_max_health"))	

@export_group("Wave Health Bar") ## For bosses or encounters that spawn waves of enemies
@export var USE_WAVE_HEALTH_BAR: bool = false ## optional group for wave health
@export var WAVE_HITSHAPE_GROUP: String = "enemy_hitshape" ## optional group for wave health
@export var WAVE_DAMAGE :float = 300.0 ## The amount to decrease health when enemies die

func hit(area: Area3D = null, damage: int = 0, play_animations: bool = true) -> bool:
	if DISABLED: return false
	if invincibility_timer: if invincibility_timer.is_stopped() == false: return false 
	if area: for immune_group in IMMUNE_GROUPS: 
		if area.is_in_group(immune_group): 
			#print('hit but immune')
			return false
	
	if damage == 0: return false
	HEALTH -= damage
	
	last_hurt_shape = area 
	if invincibility_timer: invincibility_timer.start()
	
	if DAMAGE_NUMBERS: show_damage(damage)
	
	if area:
		for node in TELEPORT_NODES_TO_HIT:
			if node is Node3D: node.global_transform.origin = area.global_transform.origin
	
	if play_animations:
		if HEALTH > 0 and damage > 0: # HURT
			if HURT_ANIMATION_PLAYER and HURT_ANIMATION_PLAYER.has_animation(HURT_ANIM):
				HURT.emit()
				HURT_ANIMATION_PLAYER.play(HURT_ANIM)
		if HEALTH <= 0: # DEATH
			if DEATH_ANIMATION_PLAYER and DEATH_ANIMATION_PLAYER.has_animation(DEATH_ANIM):
				DIED.emit()
				DISABLED = true
				DEATH_ANIMATION_PLAYER.play(DEATH_ANIM)	
		if damage < 0: # HEAL
			if HEAL_ANIMATION_PLAYER and HEAL_ANIMATION_PLAYER.has_animation(HEAL_ANIM):
				HEAL.emit()
				HEAL_ANIMATION_PLAYER.play(HEAL_ANIM)
	return true
			
func _ready():
	
	if INVINCIBILITY_COOLDOWN > 0:
		invincibility_timer = Timer.new()
		invincibility_timer.one_shot = true
		invincibility_timer.wait_time = INVINCIBILITY_COOLDOWN
		add_child(invincibility_timer)
		
	if HEALTH_KEY.is_empty(): HEALTH_KEY = Save.get_unique_key(self, "health")
	if DEATH_COUNT_KEY.is_empty(): DEATH_COUNT_KEY = Save.get_unique_key(self, "death_respawn")
	if REST_COUNT_KEY.is_empty(): REST_COUNT_KEY = Save.get_unique_key(self, "rest_respawn")
	if MAX_HEALTH_KEY.is_empty(): MAX_HEALTH_KEY = Save.get_unique_key(self, "max_health")
	
	if RESPAWN_WHEN_DEATHS_INCREMENT: _load_respawn(DEATH_COUNT_KEY, DEATHS_KEY)
	if RESPAWN_WHEN_RESTS_INCREMENT: _load_respawn(REST_COUNT_KEY, RESTS_KEY)
	
	_load_max_health()	
					
	if HEALTH_KEY.is_empty(): HEALTH_KEY = Save.get_unique_key(self, "health")
	if Save.data.has(HEALTH_KEY): HEALTH = Save.data[HEALTH_KEY]	
	else: HEALTH = MAX_HEALTH
	if HEALTH <= 0 and ROOT: ROOT.queue_free()
		
func _process(_delta):
	
	
	if USE_WAVE_HEALTH_BAR:
		var callback := Callable(self, "hit").bind(null, WAVE_DAMAGE)
		for e in get_tree().get_nodes_in_group(WAVE_HITSHAPE_GROUP):
			if e != self and not e.DIED.is_connected(callback):
				e.DIED.connect(callback)
	
		
#func _process(delta: float) -> void:
	#print(HEALTH)

func _exit_tree() -> void: ## Store when switching between scenes
	if PERSISTENT_HEALTH:
		Save.data[HEALTH_KEY] = HEALTH 
		Save.save_game()
