extends MeshInstance3D

func _process(_delta):
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera:
		global_position.x = camera.global_position.x
		global_position.z = camera.global_position.z
		material_override.set_shader_parameter("ocean_position", Vector2(-camera.global_position.x, -camera.global_position.z))
		material_override.set_shader_parameter("mesh_size", Vector2(mesh.size.x, mesh.size.y))
