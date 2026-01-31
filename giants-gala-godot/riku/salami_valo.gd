extends SpotLight3D

var treshold := 0.0
func _physics_process(delta):
	light_energy = 0
	treshold -= delta
	if treshold <= randf():
		treshold = 1.0
		light_energy = 100
		position.x = 300 * randf() - 150
		position.y = 100 * randf() - 5
		position.z = -20 + 2 * randf() - 1
		if Jattilaiset.singleton:
			look_at(Jattilaiset.singleton.jattilaiset[randi_range(0, Jattilaiset.singleton.jattilaiset.size() - 1)].global_position)
