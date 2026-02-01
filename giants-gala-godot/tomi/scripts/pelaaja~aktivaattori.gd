extends Node3D


@onready var p1: Node = get_node("../Helikopterimme_1")
@onready var p2: Node = get_node("../Helikopterimme_2")
@onready var p3: Node = get_node("../Helikopterimme_3")
@onready var p4: Node = get_node("../Helikopterimme_4")

var p1_activate: bool = false
var p2_activate: bool = false
var p3_activate: bool = false
var p4_activate: bool = false



func _ready():
	aktivoi(1,true)
	aktivoi(2,false)
	aktivoi(3,false)
	aktivoi(4,false)
	
func aktivoi(pelaaja: int, val: bool):
	if pelaaja == 1:
		p1_activate = val
		p1.set_process(p1_activate)
		p1.set_physics_process(p1_activate)
		p1.visible = p1_activate
	if pelaaja == 2:
		p2_activate = val
		p2.set_process(p2_activate)
		p2.set_physics_process(p2_activate)
		p2.visible = p2_activate
	if pelaaja == 3:
		p3_activate = val
		p3.set_process(p3_activate)
		p3.set_physics_process(p3_activate)
		p3.visible = p3_activate
	if pelaaja == 4:
		p4_activate = val
		p4.set_process(p4_activate)
		p4.set_physics_process(p4_activate)
		p4.visible = p4_activate

func _process(delta):
	var pelaajat := [p1,p2,p3,p4]
	for p in pelaajat:
		var pint :int= int(p.player_code.substr(1,1))
		if Input.is_action_just_pressed(p.player_code + "_shoot"):
			aktivoi(pint,true)
		if Input.is_action_just_pressed(p.player_code + "_ready_to_play_toggle"):
			aktivoi(pint,!p.visible)
