extends Camera3D

func _ready():
	pass

func _process(delta):
	if Jattilaiset.LOPPU:
		var l := 1 - pow(0.7, delta)
		fov = lerpf(fov, 35, l)
		return
	var t :float= Jattilaiset.get_closest_cammera_target_pos(Vector3.ZERO).length() / 100.0
	fov = lerpf(100, 30, t)
		
