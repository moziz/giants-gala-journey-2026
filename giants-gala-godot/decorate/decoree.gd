class_name Decoree extends Node3D

const JATTI_GRAFFAT :Array[PackedScene]= [
	preload("res://riku/jatti_graffat_1.tscn"),
	preload("res://riku/jatti_graffat_2.tscn"),
	preload("res://riku/jatti_graffat_3.tscn"),
	preload("res://riku/jatti_graffat_4.tscn"),
	preload("res://riku/jatti_graffat_5.tscn"),
]

@onready var raycast := RayCast3D.new()
static var jatti_index :int= 0

var ongoings: Array[AmpuOngoing] = [];

func _ready():
	jatti_index = (jatti_index + 1) % JATTI_GRAFFAT.size()
	add_child(JATTI_GRAFFAT[jatti_index].instantiate())
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
					blottaa(ongoing.target_pos_local, ongoing.target_normal_local, ongoing.payload.image, ongoing.payload.paint)
				ongoings.remove_at(i)

func blottaa(hit_pos: Vector3, hit_normal: Vector3, decaltex: Texture2D, color: Color):
	var decal = Decal.new()
	add_child(decal)
	decal.size = Vector3(3, 3, 3)
	decal.texture_albedo = decaltex
	decal.modulate = color
	decal.position = hit_pos
	decal.basis = Basis.looking_at(-hit_normal).rotated(Vector3.LEFT, PI/2)

func messhaa(hit_pos: Vector3, hit_normal: Vector3, node: Node3D):
	node.reparent(self)
	node.position = hit_pos
	node.basis = Basis.looking_at(-hit_normal).rotated(Vector3.LEFT, PI/2)
