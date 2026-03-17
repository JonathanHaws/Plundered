extends Node
@export var player_group: String = "player"
@export var anim_player: AnimationPlayer
@export var anim: String = "repair"
var inside: bool = false

func _ready():
	$Area3D.body_entered.connect(func(b): if b.is_in_group(player_group): inside = true)
	$Area3D.body_exited.connect(func(b): if b.is_in_group(player_group): inside = false)

func _process(_delta):
	if inside and Input.is_action_just_pressed("interact"):
		#print('repairing')
		if anim_player and anim_player.has_animation(anim):
			anim_player.play(anim)

func repair_hull() -> void:
	var boat = get_tree().get_first_node_in_group("PlayerShip")
	if boat and boat.has_node("HitArea"):
		var hit_area = boat.get_node("HitArea")
		hit_area.HEALTH = min(hit_area.MAX_HEALTH, hit_area.HEALTH + 150)
		
		#print("repairing boat " + str(hit_area.HEALTH - 150) + "->" + str(hit_area.HEALTH))
