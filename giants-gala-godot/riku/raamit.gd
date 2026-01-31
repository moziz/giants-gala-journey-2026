extends Control

func _process(delta):
	if Jattilaiset.end_countdown > 5:
		visible = true
		var l := 1 - pow(0.001, delta)
		modulate.a = lerpf(modulate.a, 1, l)
	else:
		modulate.a = 0
