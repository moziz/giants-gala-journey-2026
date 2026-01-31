extends Node3D

var lerp_pos :Vector3= Vector3.FORWARD;

func _process(delta: float):
	var pos :Vector3= Jattilaiset.get_closest_cammera_target_pos(global_position)
	lerp_pos = lerp_pos.lerp(pos, 1 - pow(0.2, delta))
	look_at(lerp_pos)
