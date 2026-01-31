class_name Pyssy
extends Node3D

@export var test_decal_texture: Texture2D
@export var test_mesh: Mesh

var plattrimer: Timer

func _ready() -> void:
	plattrimer = Timer.new()
	add_child(plattrimer)
	plattrimer.wait_time = 0.5
	plattrimer.timeout.connect(func():
		plattrimer.start()
		var payload = AmpuPayload.new()
		payload.payload_type = AmpuPayload.PayloadType.DECAL if randf() > .5  else AmpuPayload.PayloadType.MESH
		payload.paint = Color.RED
		payload.image = test_decal_texture
		payload.mesh = test_mesh
		
		var decoree :Decoree= Jattilaiset.current_jatti.find_child("Decoree")
		var from = global_position
		var dir = (decoree.global_position - global_position).normalized()
		
		#print(from, dir)
		
		decoree.amputulloo(
			from,
			dir,
			payload
		)
	);
	plattrimer.start()

func maali_valittu(color: Color):
	pass

func objekti_valittu(objektin_tyyppi_tms: int):
	pass
