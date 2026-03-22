extends Control
@export var sail_textures: Array[Texture2D] = []
@export var sigil_size: Vector2 = Vector2(50, 50)
@export var x_offset: float = -50.0
@onready var previous_boat_count: int = 0

func _physics_process(_delta: float) -> void:
	var boats = get_tree().get_nodes_in_group("boats")
	if boats.size() == previous_boat_count: return 
	previous_boat_count = boats.size() 

	for child in get_children(): child.queue_free()

	var i = 0
	for boat in boats:
		#if boat.name == "PlayerShip": continue
		
		var sigil = TextureRect.new()
		sigil.texture = sail_textures[boat.sigil]
		sigil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sigil.size = sigil_size
		
		sigil.position.x = i * x_offset
		sigil.modulate = Color(0, 0, 0, 0.3)
		
		add_child(sigil)
				
		i += 1
