extends RigidBody3D

@onready var propellit: Node = get_node("Propellit")
@onready var infotext: Label3D = get_node("infotext")

@export var auto_float: bool = true

var auto_float_target_altitude = 10
var auto_float_power_max: float = 1000.0
var auto_float_force: float = 0


func _physics_process(delta) -> void:
	if auto_float:
		var multi = 1
		# check downward speed and apply up force
		if global_position.y < auto_float_target_altitude:
			# slowdown when closer than 10 and going up
			var missing = auto_float_target_altitude - global_position.y

			if missing < 10:
				multi = missing / 10.0;
			if missing > 0:
				auto_float_force = lerp(auto_float_force, auto_float_power_max, 0.5)
			
		else:
			auto_float_force *= 0.5
			
		# damp
		apply_force(Vector3.UP * auto_float_force * multi)
		auto_float_force *= 0.9
	infotext.text = "Altitude: %.2f\nAltitude target: %.2f" % [global_position.y, auto_float_target_altitude]
