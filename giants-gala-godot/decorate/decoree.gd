class_name Decoree extends Node3D

@onready var raycast = RayCast3D.new()

var ongoings: Array[AmpuOngoing] = [];

func _ready():
	add_child(raycast)

func amputulloo(from_global: Vector3, dir_global: Vector3, payload: AmpuPayload):
	var from_local = to_local(from_global)
	raycast.position = from_local
	raycast.target_position = raycast.to_local(from_global + dir_global * 100)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		#print("osuu!")
		var hit_pos = to_local(raycast.get_collision_point())
		var normal = global_transform.basis.inverse() * raycast.get_collision_normal()
		
		var collider = raycast.get_collider()
		
		var ongoing = AmpuOngoing.new(
			self,
			from_local,
			payload,
			collider,
			hit_pos,
			normal
		)
		ongoings.push_back(ongoing);
	else:
		print("ei osu!")

func _process(delta: float) -> void:
	if !ongoings.is_empty():
		for i in range(ongoings.size() - 1, 0, -1):
			var ongoing = ongoings[i]
			ongoing.tick()
			if ongoing.finished:
				if ongoing.payload.payload_type == AmpuPayload.PayloadType.MESH:
					messhaa(ongoing.target_pos_local, ongoing.target_normal_local, ongoing.payload.mesh)
				elif ongoing.payload.payload_type == AmpuPayload.PayloadType.DECAL:
					blottaa(ongoing.target_pos_local, ongoing.target_normal_local, ongoing.payload.image)
				ongoings.remove_at(i)

func blottaa(hit_pos: Vector3, hit_normal: Vector3, decaltex: Texture2D):
	var decal = Decal.new()
	add_child(decal)
	decal.size = Vector3(3, 3, 3)
	decal.texture_albedo = decaltex
	decal.position = hit_pos
	decal.basis = Basis.looking_at(-hit_normal).rotated(Vector3.LEFT, PI/2)

func messhaa(hit_pos: Vector3, hit_normal: Vector3, mesh: Mesh):
	var mesh_node = MeshInstance3D.new()
	mesh_node.mesh = mesh
	add_child(mesh_node)
	mesh_node.position = hit_pos
	mesh_node.basis = Basis.looking_at(-hit_normal).rotated(Vector3.LEFT, PI/2)
