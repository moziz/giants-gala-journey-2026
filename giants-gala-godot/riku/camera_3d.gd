extends Camera3D

func _ready():
	pass

func _process(delta):
	if !Jattilaiset.LOPPU:
		return
		
	var l := 1 - pow(0.7, delta)
	fov = lerpf(fov, 35, l)
