extends Node3D
@export var sail_textures: Array[Texture2D] = [] 
@onready var shader_param_name: String = "texture_albedo" 
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

func _ready() -> void:
	_delete_extra_sails(front_sails)
	_delete_extra_sails(middle_sails)
	_delete_extra_sails(back_sails)
	
	apply_texture(front_sails, 0)
	apply_texture(back_sails, 0)
	apply_texture(back_sails, 0)
	# assign random textures to all remaining sails
	#for sail_group in [front_sails, middle_sails, back_sails]:
		#for name in sail_group:
			#if sail_textures.size() == 0:
				#continue
			#apply_texture([name], randi() % sail_textures.size())

func _delete_extra_sails(sail_names: Array[String]) -> void:
	while sail_names.size() > 1:
		var index = randi() % sail_names.size()
		var sail_node = $sails.get_node_or_null(sail_names[index])
		if sail_node and sail_node is MeshInstance3D:
			sail_node.queue_free()
		sail_names.remove_at(index)
		
func apply_texture(sail_names: Array[String], texture_index: int = 0) -> void:
	for ship_name in sail_names:
		var sail_node = $sails.get_node_or_null(ship_name)
		
		if not sail_node: continue
		if not sail_node is MeshInstance3D: continue

		var mat = sail_node.get_active_material(0)
		if not mat or not mat is ShaderMaterial: continue

		mat.set_shader_parameter(shader_param_name, sail_textures[texture_index])
		#print('getting here')

		

		
