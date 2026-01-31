extends Node3D

@onready var propellit: Node = get_node("Runko/Propellit")
@onready var infotext: Label3D = get_node("infotext")
@onready var control_text: Label3D = get_node("controlText")
@export var my_camera_name: StringName = &"Camera3D"
@export var controls_text: String = "Movement: JL, IK, YH"

var my_camera: Camera3D
var show_info = false

var upward_power: float = 10.0
var sideward_power: float = 10.0
var forward_power: float = 10.0

@export var player_code = "p1"

func _ready() -> void:
	my_camera = _find_node_by_name(get_tree().current_scene, my_camera_name)
	if my_camera == null:
		push_error("Missä on mun kamera? %s" % [my_camera_name])
		return
	control_text.text = controls_text
		
func _process(delta):
		
	# handle _p1_ inputs
	var up_force_input = 0
	if Input.is_action_pressed(player_code + "_thrust_up"):
		up_force_input = 1
	if Input.is_action_pressed(player_code + "_thurst_down"):
		up_force_input = -1
	if up_force_input != 0:
		global_position.y +=  upward_power * delta * up_force_input
	
	var directions = get_camera_xz_basis(my_camera)
	
	var side_force_input = 0
	if Input.is_action_pressed(player_code + "_thrust_right"):
		side_force_input = 1
	if Input.is_action_pressed(player_code + "_thurst_left"):
		side_force_input = -1
		
	if side_force_input != 0:
		global_position += directions["right"] * sideward_power * delta * side_force_input
		
	var forward_force_input = 0
	if Input.is_action_pressed(player_code + "_thrust_forward"):
		forward_force_input = 1
	if Input.is_action_pressed(player_code + "_thurst_backward"):
		forward_force_input = -1
		
	if forward_force_input != 0:
		global_position += directions["forward"] * forward_power * delta * forward_force_input
		
		
	if Input.is_action_just_pressed(player_code + "_show_info_toggle"):
		show_info = not show_info
	if show_info:
		infotext.text = "Altitude: %.2f\nAltitude target: %.2f\nLinVelY: %.2f\nAutofloat F: %.2f " % [position.x, position.y, position.z]
	else:
		infotext.text = ""
	
func _find_node_by_name(root: Node, name: StringName) -> Node3D:
	if root.name == name and root is Node3D:
		return root as Node3D
	for child in root.get_children():
		var found := _find_node_by_name(child, name)
		if found != null:
			return found
	return null

func get_camera_xz_basis(cam: Camera3D) -> Dictionary:
	# Godot forward is -Z in basis.
	var fwd: Vector3 = -cam.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	var right: Vector3 = cam.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	# Re-orthonormalize
	right = right - fwd * right.dot(fwd)
	right = right.normalized()

	return {"forward": fwd, "right": right}
