class_name Pyssy
extends Node3D

@export var decal_textures: Array[Texture2D]
@export var test_mesh: Mesh

var plattrimer: Timer

var prepPayload: AmpuPayload

func _ready() -> void:
	plattrimer = Timer.new()
	add_child(plattrimer)
	plattrimer.wait_time = 0.5
	plattrimer.timeout.connect(func():
		ampuloi()
		plattrimer.start()
	);
	plattrimer.start()

func maali_valittu(color: Color):
	prepPayload = AmpuPayload.new()
	prepPayload.payload_type = AmpuPayload.PayloadType.DECAL
	prepPayload.image = decal_textures[randi_range(0, decal_textures.size() - 1)]
	prepPayload.paint = color
	pass

func objekti_valittu(objekti_scene: PackedScene, color: Color):
	prepPayload = AmpuPayload.new()
	prepPayload.payload_type = AmpuPayload.PayloadType.MESH
	prepPayload.paint = color
	prepPayload.mesh = objekti_scene.instantiate()
	if prepPayload.mesh is Varjaa:
		prepPayload.mesh.varjaa(color)
	pass
	
func ampuloi():
	if !prepPayload:
		return
	
	var decoree :Decoree= Jattilaiset.current_jatti.find_child("Decoree")
	var from = global_position
	var dir = global_basis * Vector3.FORWARD
	
	decoree.amputulloo(from, dir, prepPayload)
