extends Node
@export var FLY_SPEED: float = 10.0
@export var ASCEND_SPEED: float = 50.0
@export var DESCEND_SPEED: float = 50.0
@export var SPRINT_MULTIPLIER = 2.1
@export var PLAYER: Node 
@export var MESH: Node 
@export var SPRING_ARM: Node 
@export var CAMERA: Node 
@export var BODY_SHAPE: Node 
@export var HITBOX_SHAPE: Node 
@export var DAMAGE_SHAPE: Node
@export var ANIMATION_PLAYER: AnimationPlayer
@export var ENTER_ANIMATION: String = "GOD"
@export var EXIT_ANIMATION: String= "IDLE"
var mode := false
var last_position: Vector3

func _ready():
	
	if not OS.is_debug_build():
		queue_free()

func _physics_process(_delta):
	if Input.is_action_just_pressed("god_mode"):
		mode = !mode
		#if DAMAGE_SHAPE: DAMAGE_SHAPE.disabled = !DAMAGE_SHAPE.disabled
		if mode and ANIMATION_PLAYER and ENTER_ANIMATION != "":
			ANIMATION_PLAYER.play(ENTER_ANIMATION)
		elif not mode and ANIMATION_PLAYER and EXIT_ANIMATION != "":
			ANIMATION_PLAYER.play(EXIT_ANIMATION)
		
	if mode: 
		#if Input.is_action_just_pressed("get_wisp"):
			#Save.data["wisp"] = Save.data.get("wisp", 0) + 50
		
		if PLAYER: PLAYER.global_transform.origin = last_position
			
		if BODY_SHAPE: BODY_SHAPE.disabled = true
		if HITBOX_SHAPE: HITBOX_SHAPE.disabled = true
		if DAMAGE_SHAPE: DAMAGE_SHAPE.disabled = false
		
		var keyboard_vector := Vector2.ZERO
		if InputMap.has_action("keyboard_left") and InputMap.has_action("keyboard_right") and InputMap.has_action("keyboard_forward") and InputMap.has_action("keyboard_back"):
			keyboard_vector = Input.get_vector("keyboard_left","keyboard_right","keyboard_forward","keyboard_back")

		var controller_vector := Vector2.ZERO
		if InputMap.has_action("controller_left") and InputMap.has_action("controller_right") and InputMap.has_action("controller_forward") and InputMap.has_action("controller_back"):
			controller_vector = Input.get_vector("controller_left","controller_right","controller_forward","controller_back")
		var input_vector := keyboard_vector + controller_vector
	
		if InputMap.has_action("jump") and Input.is_action_pressed("jump"):
			if PLAYER: PLAYER.position.y += ASCEND_SPEED * _delta
		if InputMap.has_action("descend") and Input.is_action_pressed("descend"):
			if PLAYER: PLAYER.position.y -= DESCEND_SPEED * _delta
	
		if PLAYER: PLAYER.velocity = Vector3.ZERO
	
		if input_vector.length() > 0:
			if CAMERA and PLAYER:
				var direction = (CAMERA.global_transform.basis.z * input_vector.y + CAMERA.global_transform.basis.x * input_vector.x).normalized()
				var speed_factor = SPRINT_MULTIPLIER
				if InputMap.has_action("walk") and Input.is_action_pressed("walk") or (controller_vector.length() > .4 and controller_vector.length() < 0.75):
					speed_factor = 1.0

				PLAYER.position += direction * FLY_SPEED * speed_factor * _delta
			
	else:
		if BODY_SHAPE: BODY_SHAPE.disabled = false
		if HITBOX_SHAPE: HITBOX_SHAPE.disabled = false
		if DAMAGE_SHAPE: DAMAGE_SHAPE.disabled = true
		
	if SPRING_ARM: SPRING_ARM.collision_mask = 0 if mode else 1

	if PLAYER: last_position = PLAYER.global_transform.origin  # save position
