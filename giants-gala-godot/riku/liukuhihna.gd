extends Node3D

@onready var kamera: Node3D = get_node("../PelaajienYmparisto/Camera3D")


func _process(delta):
	if !Jattilaiset.LOPPU:
		if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_SHIFT):
			position.x -= delta * 1000
		
		# speed up when far away
		var lähin_jätti = Jattilaiset.get_closest_cammera_target(kamera.global_position)
		var speed = 1
		var distance = 0
		if lähin_jätti == null:
			speed = 20
		else:
			distance = (kamera.global_position - lähin_jätti.global_position).length()
			if distance > 100 and Jattilaiset.countdown <= 0.0:
				speed = 10
			else:
				# slow down when hit distance
				speed = 0.5
		position.x -= delta * 10 * speed
	else:
		# LOPPU
		var l := 1 - pow(0.9, delta)
		position.x = position.x * l
