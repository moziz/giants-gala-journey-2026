extends Node3D

@export var decoree: Decoree
@export var fly_speed: float = 8

var plattrimer: Timer
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	
	plattrimer = Timer.new()
	add_child(plattrimer)
	plattrimer.wait_time = 0.5
	plattrimer.timeout.connect(func():
		print("test")
		plattrimer.start()
		var payload = AmpuPayload.new()
		payload.payload_type = AmpuPayload.PayloadType.PAINT
		payload.paint = Color.RED
		
		decoree = Jattilaiset.current_jatti.find_child("Decoree")
		var from = global_position
		var dir = (decoree.global_position - global_position).normalized()
		
		print(from, dir)
		
		decoree.amputulloo(
			from,
			dir,
			payload
		)
	);
	plattrimer.start()
	
func _process(delta: float) -> void:
	var move_dir = Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_I):
		move_dir += Vector3.UP
	if Input.is_physical_key_pressed(KEY_K):
		move_dir += Vector3.DOWN
	if Input.is_physical_key_pressed(KEY_J):
		move_dir += Vector3.LEFT
	if Input.is_physical_key_pressed(KEY_L):
		move_dir += Vector3.RIGHT
	if Input.is_physical_key_pressed(KEY_U):
		move_dir += Vector3.BACK
	if Input.is_physical_key_pressed(KEY_O):
		move_dir += Vector3.FORWARD
		
	if move_dir.length_squared() > 0:
		move_dir = move_dir.normalized()
	
	position += move_dir * delta * fly_speed
