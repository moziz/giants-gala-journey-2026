class_name Varjaa
extends Node3D

@export var varjattavat_lapset :Array[Node3D]

func varjaa(c: Color):
	for tex in varjattavat_lapset:
		if !tex:
			continue
		var meshinst : MeshInstance3D = tex as MeshInstance3D
		if meshinst:
			meshinst.mesh = meshinst.mesh.duplicate(true)
			var mat = meshinst.mesh.surface_get_material(0)
			if mat:
				mat.albedo_color = c
		for asdf :MeshInstance3D in tex.find_children("*", "MeshInstance3D", true):
			asdf.mesh = asdf.mesh.duplicate(true)
			var mat = asdf.mesh.surface_get_material(0)
			if mat:
				mat.albedo_color = c
