class_name Pyssy
extends Node3D

@export var decal_textures: Array[Texture2D]
@export var test_mesh: Mesh

var plattrimer: Timer

#func _ready() -> void:
#	plattrimer = Timer.new()
#	add_child(plattrimer)
#	plattrimer.wait_time = 0.5
#	plattrimer.timeout.connect(func():
#		ampuloi()
#		plattrimer.start()
#	);
#	plattrimer.start()

var valittu_scene: PackedScene
var valittu_color: Color
var valittu_type: AmpuPayload.PayloadType
var ei_valintaa: bool = true

func valinnan_poisto():
	ei_valintaa = true

func maali_valittu(color: Color):
	ei_valintaa = false
	valittu_type = AmpuPayload.PayloadType.DECAL
	valittu_color = color

func objekti_valittu(objekti_scene: PackedScene, color: Color):
	ei_valintaa = false
	valittu_type = AmpuPayload.PayloadType.MESH
	valittu_scene = objekti_scene
	valittu_color = color
	
func ampuloi():
	if ei_valintaa:
		return
	var payload = AmpuPayload.new()
	payload.payload_type = valittu_type
	payload.paint = valittu_color
	if valittu_type == AmpuPayload.PayloadType.MESH:
		payload.mesh = valittu_scene.instantiate()
		var bodies: Array[Node] = payload.mesh.find_children("*", "StaticBody3D")
		for body in bodies:
			body.set_collision_layer_value(1, false)
		if payload.mesh is Varjaa:
			payload.mesh.varjaa(valittu_color)
	if payload.payload_type == AmpuPayload.PayloadType.DECAL:
		payload.image = decal_textures[randi_range(0, decal_textures.size() - 1)]
	
	var decoree :Decoree= Jattilaiset.current_jatti.find_child("Decoree")
	var from = global_position
	var dir = global_basis * Vector3.FORWARD
	
	decoree.amputulloo(from, dir, payload)
