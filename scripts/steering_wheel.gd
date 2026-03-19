extends Area3D
@export var boat: RigidBody3D
@export var player_group: String = "player"
@export var player_animator_group: String = "player_anim"
var player: CharacterBody3D
var player_anim: AnimationPlayer
var in_range_of_steering: bool = false
var steering: bool = false

func _on_enter_steer(body):
	if body.is_in_group(player_group):
		in_range_of_steering = true

func _on_exit_steer(body):
	if body.is_in_group(player_group):
		in_range_of_steering = false

func _ready() -> void:
	if not boat: boat = get_parent()
	body_entered.connect(func(b): _on_enter_steer(b))
	body_exited.connect(func(b): _on_exit_steer(b))
	player = get_tree().get_first_node_in_group(player_group)	
	player_anim = get_tree().get_first_node_in_group(player_animator_group)

func get_movement_vector() -> Vector3:
	return Vector3(
		int(Input.is_action_pressed("keyboard_right")) - int(Input.is_action_pressed("keyboard_left")), 0,
		int(Input.is_action_pressed("keyboard_forward")) - int(Input.is_action_pressed("keyboard_back"))
	)

func _process(_delta):
	
	if steering: # SAIL SOUND
		if Input.is_action_just_pressed("keyboard_forward") or Input.is_action_just_pressed("keyboard_back"):
			if not $SailSound.playing:
				$SailSound.play()
	
	# WHEEL SOUND
	var movement_vector = get_movement_vector()
	if steering and movement_vector.x != 0 and not $SteeringSound.playing:
		$SteeringSound.play()
	if $SteeringSound.playing:
		if movement_vector.x == 0 or not steering:
			$SteeringSound.stop()
	
	if boat.name == "PlayerShip": # Can Only Pilot Your Ship
		if Input.is_action_just_pressed("interact"):
			if steering:
				steering = false
				player_anim.play("Idle")
				player.speed_multiplier = 1
				player.mouse_delta = Vector2.ZERO
				player.velocity = Vector3.ZERO
			elif in_range_of_steering:
				steering = true
				$SteerSound.play()
				player.global_transform = $SteerSpot.global_transform
				player_anim.play("Steer")
				player.speed_multiplier = 0
				player.velocity = Vector3.ZERO

	ai_steering(_delta)
	player_steering(_delta)

func ai_steering(_delta):
	if boat.name == "PlayerShip": return
	
	var targets = get_tree().get_nodes_in_group("player_ship_targets")
	if targets.size() == 0: return

	#print('piloting ai boat')

	var forward = -global_transform.basis.z.normalized()
	var best_score = -INF
	var best_target = null

	# add scoring to keep ship in optimal distance away

	for t in targets:
		var to_target = (t.global_position - global_position).normalized()
		var dist = global_position.distance_to(t.global_position)
		var alignment = forward.dot(to_target)  # 1 = straight ahead, -1 = behind
		var score = alignment / dist  # high alignment + close distance
		if score > best_score:
			best_score = score
			best_target = t

	if not best_target: return

	# turn shortest way to target
	var dir = (best_target.global_position - global_position).normalized()
	var angle = atan2(dir.x, dir.z) - atan2(forward.x, forward.z)
	angle = wrapf(angle, -PI, PI)

	boat.apply_boat_controls(1, sign(angle), _delta)

func player_steering(_delta) -> void:
	if not boat.name == "PlayerShip": return
	if not steering: return
	
	var movement_vector = get_movement_vector()

	$wheel/Wheel.rotate_z(-movement_vector.x * 0.02)

	player.global_position = $SteerSpot.global_position
	
	boat.apply_boat_controls(movement_vector.z, -movement_vector.x, _delta)
	

	
