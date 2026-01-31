class_name Pyssy
extends Node3D

func maali_valittu(color: Color):
	pass

func objekti_valittu(objektin_tyyppi_tms: int):
	pass

var plattrimer: Timer

func _ready() -> void:
	plattrimer = Timer.new()
	add_child(plattrimer)
	plattrimer.wait_time = 0.5
	plattrimer.timeout.connect(func():
		plattrimer.start()
		var payload = AmpuPayload.new()
		payload.payload_type = AmpuPayload.PayloadType.PAINT
		payload.paint = Color.RED
		
		var decoree :Decoree= Jattilaiset.get_closest_cammera_target(global_position).find_child("Decoree")
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
