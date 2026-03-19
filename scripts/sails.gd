extends Node3D
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

func _delete_extra_sails(sail_names: Array[String]) -> void:
	while sail_names.size() > 1:
		var index = randi() % sail_names.size()
		var sail_node = $sails.get_node_or_null(sail_names[index])
		if sail_node and sail_node is MeshInstance3D:
			sail_node.queue_free()
		sail_names.remove_at(index)
