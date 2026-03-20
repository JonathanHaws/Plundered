extends Node3D
var player_ship: Node3D
var velocity: Vector3 = Vector3.ZERO
var angular_velocity: Vector3 = Vector3.ZERO
var gravity: float = 9.8
var buoyancy: float = 12.0
var air_damping: float = 0.99
var water_damping: float = 0.95

func add_bounty(amount: int = 25):
	Save.data["bounty"] = Save.data.get("bounty", 0) + amount
	Save.save_game()

func apply_random_force():
	transform.basis = Basis.from_euler(Vector3(
		randf_range(0.0, TAU),
		randf_range(0.0, TAU),
		randf_range(0.0, TAU)
	))

	velocity = Vector3(
		randf_range(-13.0, 13.0),
		randf_range(4.0, 10.0),
		randf_range(-13.0, 13.0)
	)

	angular_velocity = Vector3(
		randf_range(-2.0, 2.0),
		randf_range(-2.0, 2.0),
		randf_range(-2.0, 2.0)
	)

func _ready():
	player_ship = get_tree().get_first_node_in_group("PlayerShip")


func _physics_process(delta):
	
	#print(global_position.distance_to(player_ship.global_position))
	if player_ship and global_position.distance_to(player_ship.global_position) > 200.0:
		queue_free()
		return
	
	if global_position.y > 0.0:
		velocity.y -= gravity * delta
		velocity *= air_damping
		angular_velocity *= air_damping
	else:
		velocity.y += buoyancy * delta
		velocity *= water_damping
		angular_velocity *= water_damping

	global_position += velocity * delta
	rotate_object_local(Vector3(1,0,0), angular_velocity.x * delta)
	rotate_object_local(Vector3(0,1,0), angular_velocity.y * delta)
	rotate_object_local(Vector3(0,0,1), angular_velocity.z * delta)
