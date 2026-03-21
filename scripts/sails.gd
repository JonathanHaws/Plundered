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

func _ready() -> void:
	if not boat: boat = get_parent()
	#print(boat.sigils[boat.sigil])
	
	_delete_extra_sails(front_sails)
	_delete_extra_sails(middle_sails)
	_delete_extra_sails(back_sails)

func _physics_process(_delta: float) -> void:
	poll()

func poll() -> void:
	if not boat: return
	apply_sigil(front_sails, boat.sigil)
	apply_sigil(middle_sails, boat.sigil)
	apply_sigil(back_sails, boat.sigil)
	
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

		
