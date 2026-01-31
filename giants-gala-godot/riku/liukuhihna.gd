extends Node3D


func _process(delta):
	if !Jattilaiset.LOPPU:
		if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_SHIFT):
			position.x -= delta * 1000
		position.x -= delta * 10
		return
	var l := 1 - pow(0.9, delta)
	position.x = position.x * l
