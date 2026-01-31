class_name Jattilaiset
extends Node3D

static var singleton : Jattilaiset

func _ready():
	singleton = self

static func get_closest_cammera_target_pos(src: Vector3):
	var closest := Vector3.FORWARD * 10000.0
	var min_dist := 10000.0
	for child: Node3D in singleton.get_children():
		var target : Node3D = child.find_child("CameraTarget", true)
		if !target:
			continue
		var pos :Vector3= child.global_position
		var dist := (src - pos).length()
		if min_dist > dist:
			#print(child, ", ", src, ", ", child.position, ", min_dist=", min_dist, ", dist=", dist, ", ", pos)
			min_dist = dist
			closest = pos
	return closest
