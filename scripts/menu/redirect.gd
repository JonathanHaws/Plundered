extends Control ## Script for switching scenes easily... Can be used on anything but most likely button
@export_file("*.tscn") var scene_file: String ## Target scene to load and replace the root with
@export var node_to_replace: Node ## if no node to replace is specified will replace the entire tree (USUALLY WHAT IS WANTED)
@export var animation_player: AnimationPlayer ## Used to speicfy fade to black... or other transition things
@export var redirect_animation_name: String = "redirect" ## redirect() must be called manually in animation if animation player is used
@export var is_back_button: bool = false ## Makes it so pressing 'menu back' input on controller navigates back
var scene = null

func _unhandled_input(event: InputEvent) -> void:
	if is_back_button and event.is_action_pressed("menu_back"): 
		_on_pressed() 
		
func _ready() -> void:
	if scene_file != "" and ResourceLoader.exists(scene_file): scene = load(scene_file)
	if has_signal("pressed"): self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if not scene: return
	if animation_player:
		#print("test", Engine.time_scale)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Engine.time_scale = 1.0
		animation_player.play(redirect_animation_name)
	else: redirect()
	
func redirect() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if node_to_replace:
		var parent = node_to_replace.get_parent()
		node_to_replace.queue_free()
		parent.add_child(scene.instantiate())
		return
	get_tree().paused = false 
	Engine.time_scale = 1.0 ## Reset If changing the scene eg.(Pause Menu To Main Menu)
	get_tree().change_scene_to_packed(scene)
