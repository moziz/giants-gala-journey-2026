class_name Decoree extends Node3D

@export var decaltex: Texture2D
@onready var raycast := RayCast3D.new()

func _ready():
	add_child(raycast)

func amputulloo(from_global: Vector3, dir_global: Vector3, payload: AmpuPayload):
	raycast.position = to_local(from_global)
	raycast.target_position = raycast.to_local(from_global + dir_global * 100)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		print("osuu!")
		var hit_pos = to_local(raycast.get_collision_point())
		var normal = global_transform.basis.inverse() * raycast.get_collision_normal()
		blottaa(hit_pos, normal, Color.BROWN, 0.3)
	else:
		print("ei osu!")

func blottaa(hit_pos: Vector3, hit_normal: Vector3, color: Color, radius: float):
	var decal = Decal.new()
	add_child(decal)
	decal.size = Vector3(.5, .5, .5)
	decal.texture_albedo = decaltex
	decal.position = hit_pos
	decal.basis = Basis.looking_at(-hit_normal).rotated(Vector3.LEFT, PI/2)
		
