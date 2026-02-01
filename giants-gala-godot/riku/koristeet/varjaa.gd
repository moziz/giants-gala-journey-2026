class_name Varjaa
extends Node3D

@export var varjattavat_lapset :Array[Node3D]

func varjaa(c: Color):
	for tex in varjattavat_lapset:
		pass
		#if tex
		#tex.self_modulate = c
