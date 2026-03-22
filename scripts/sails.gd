extends Node3D
@export var boat: RigidBody3D
@export var sail_textures: Array[Texture2D] = [] 
@export var sail_colors: Array[Color] = []	

@onready var front_sails: Array[String] = [
	"MediumFront",
	"BigFront"]
@onready var middle_sails: Array[String] = [
	"SmallMid",
	"MediumMid",
	"BigMid"]
@onready var back_sails: Array[String] = [
	"MediumBack",
	"BigBack"]
func _delete_extra_sails(sail_names: Array[String]) -> void:
	while sail_names.size() > 1:
		var index = randi() % sail_names.size()
		var sail_node = $sails.get_node_or_null(sail_names[index])
		if sail_node and sail_node is MeshInstance3D:
			sail_node.queue_free()
		sail_names.remove_at(index)

@export var player_group: String = "player"
var in_range_of_sail
func _on_enter_sail(body):
	if body.is_in_group(player_group):
		in_range_of_sail = true
func _on_exit_sail(body):
	if body.is_in_group(player_group):
		in_range_of_sail= false


func _ready() -> void:
	if not boat: boat = get_parent()
	#print(boat.sigils[boat.sigil])
	
	_delete_extra_sails(front_sails)
	_delete_extra_sails(middle_sails)
	_delete_extra_sails(back_sails)
	
	if boat.name == "PlayerShip":
		$Area3D.body_entered.connect(_on_enter_sail)
		$Area3D.body_exited.connect(_on_exit_sail)
		$Area3D2.body_entered.connect(_on_enter_sail)
		$Area3D2.body_exited.connect(_on_exit_sail)
		$Area3D3.body_entered.connect(_on_enter_sail)
		$Area3D3.body_exited.connect(_on_exit_sail)
	else: 
		$Area3D.queue_free()
		$Area3D2.queue_free()
		$Area3D3.queue_free()
		
func _physics_process(_delta: float) -> void:
	poll()

func poll() -> void:
	if not boat: return
	apply_sigil(front_sails, boat.sigil)
	apply_sigil(middle_sails, boat.sigil)
	apply_sigil(back_sails, boat.sigil)
	
	

	
	if boat.name == "PlayerShip":
		
		if in_range_of_sail:
			$Prompt.visible = true
		else:
			$Prompt.visible = false
		
		if Input.is_action_just_pressed("interact") and in_range_of_sail: # Change sail
			var owned: Array = Save.data.get("collected_sigils", [])
			var next = boat.sigil
			
			var unlock_all_sigils: bool = false # easy toggle for testing
			
			for i in boat.sigils.size():
				next = (next + 1) % boat.sigils.size()
				if unlock_all_sigils or boat.sigils[next] == "none" or owned.has(boat.sigils[next]):
					break
			
			boat.sigil = next
			$Audio.play_random_child()
			
			var sigil_name: String = boat.sigils[boat.sigil]
			if sigil_name == "none":
				boat.speed = 1000
				boat.steer = 100
				boat.cannon_cooldown_min = 0.8
				
			if sigil_name == "beer":
				boat.speed = 800
				boat.steer = 80
				boat.cannon_cooldown_min = 0.8
				boat.set_max_health(800)
				
			if sigil_name == "turtle":
				boat.speed = 500
				boat.steer = 50	
				boat.cannon_cooldown_min = 0.8
				boat.set_max_health(1250)
				
			if sigil_name == "doliphin":
				
				#print('here', boat.speed, boat.steer)
				boat.speed = 1500
				boat.steer = 150
				boat.cannon_cooldown_min = 0.8
				boat.set_max_health(1000)
				
			if sigil_name == "whale":
				boat.speed = 900
				boat.steer = 90
				boat.cannon_cooldown_min = 0.8
				boat.set_max_health(1500)
				
			if sigil_name == "shark":
				boat.speed = 1000
				boat.steer = 100
				boat.cannon_cooldown_min = 0.3
				boat.set_max_health(1000)

	#print(boat.sigil)
	
func apply_sigil(sail_names: Array[String], sail_index: int = 0) -> void:
	
	for ship_name in sail_names:
		var sail_node = $sails.get_node_or_null(ship_name)
		
		if not sail_node: continue
		if not sail_node is MeshInstance3D: continue

		var mat = sail_node.get_active_material(0)
		if not mat or not mat is ShaderMaterial: continue
		
		# make material unique so each sail can have its own texture
		var new_mat = mat.duplicate() as ShaderMaterial
		sail_node.set_surface_override_material(0, new_mat)

		var texture_index = clamp(sail_index, 0, sail_textures.size() - 1)
		var color_index = clamp(sail_index, 0, sail_colors.size() - 1)

		if not sail_textures.size() == 0:
			if sail_textures[texture_index]:
				new_mat.set_shader_parameter("texture_albedo", sail_textures[texture_index])
				new_mat.set_shader_parameter("has_sigil_texture", true)
			else:
				new_mat.set_shader_parameter("has_sigil_texture", false)
		
		if not sail_colors.size() == 0:

			new_mat.set_shader_parameter("background_color", sail_colors[color_index])
			#print('assigning color: ', sail_colors[color_index])
		
		#print('getting here')

		
