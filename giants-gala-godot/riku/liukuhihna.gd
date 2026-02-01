extends Node3D

# Reference path for getting time_scale from on_rails_controller
var _OnRailsController: Script = preload("res://riku/on_rails_controller.gd")

func _process(delta):
	# Apply slow motion scale from OnRailsController (only affects scrolling)
	var scaled_delta = delta * _OnRailsController.time_scale
	
	if !Jattilaiset.LOPPU:
		if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_SHIFT):
			position.x -= scaled_delta * 1000
		position.x -= scaled_delta * 5  # Slower scrolling (was 10)
		return
	var l := 1 - pow(0.9, scaled_delta)
	position.x = position.x * l
