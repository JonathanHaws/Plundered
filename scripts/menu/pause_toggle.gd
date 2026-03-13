# Make sure in main mneu put a node2d with this script which is hidden...
# That way if the player is coming back to the main menu from a pause menu the game will be unpaused 
# If this is not done menu will seem unresponsive and glitchy

extends Node
func _ready() -> void: 
	# Make sure process mode for this node is 'always' so when game pauses it doesnt pause this scripts functions aswell
	process_mode = Node.PROCESS_MODE_ALWAYS 
	if not self.visible: toggle(false)

func toggle(paused: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if paused else Input.MOUSE_MODE_CAPTURED
	self.visible = paused
	Engine.time_scale = 0 if paused else 1
	get_tree().paused = paused
	
	if self.visible:
		if Config and Config.has_method("save_window_transform"): Config.save_window_transform()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		toggle(not self.visible) 
