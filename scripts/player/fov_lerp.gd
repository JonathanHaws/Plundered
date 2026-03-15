extends Node
@export var camera_node: Camera3D
@export var lerp_speed: float = 0.2
@export var target_fov: float = 80.0

func _physics_process(_delta):
	if camera_node: camera_node.fov = lerp(camera_node.fov, target_fov, lerp_speed)
