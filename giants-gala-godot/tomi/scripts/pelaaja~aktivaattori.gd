extends Node3D


@onready var p1: Node = get_node("../Helikopterimme_1")
@onready var p2: Node = get_node("../Helikopterimme_2")
@onready var p3: Node = get_node("../Helikopterimme_3")
@onready var p4: Node = get_node("../Helikopterimme_4")

var p1_activate: bool = true
var p2_activate: bool = true
var p3_activate: bool = true
var p4_activate: bool = true

func _process(delta):
	if Input.is_action_just_pressed("p1_ready_to_play_toggle"):
		p1_activate = not p1_activate
		p1.set_process(p1_activate)
		p1.set_physics_process(p1_activate)
		p1.visible = p1_activate
	if Input.is_action_just_pressed("p2_ready_to_play_toggle"):
		p2_activate = not p2_activate
		p2.set_process(p2_activate)
		p2.set_physics_process(p2_activate)
		p2.visible = p2_activate
	if Input.is_action_just_pressed("p3_ready_to_play_toggle"):
		p3_activate = not p3_activate
		p3.set_process(p3_activate)
		p3.set_physics_process(p3_activate)
		p3.visible = p3_activate
	if Input.is_action_just_pressed("p4_ready_to_play_toggle"):
		p4_activate = not p4_activate
		p4.set_process(p4_activate)
		p4.set_physics_process(p4_activate)
		p4.visible = p4_activate
