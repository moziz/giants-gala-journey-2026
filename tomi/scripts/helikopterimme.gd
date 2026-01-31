extends RigidBody3D

@onready var propellit: Node = get_node("Propellit")
@onready var infotext: Label3D = get_node("infotext")

@export var auto_float: bool = true

var auto_float_target_altitude = 10
var auto_float_power_max: float = 1000.0
var auto_float_force: float = 0

var upward_power: float = 100_000.0
var sideward_power: float = 100_000.0
var forward_power: float = 100_000.0

var max_y_speed: float = 10.0
var max_x_speed: float = 10.0
var max_z_speed: float = 10.0


func _physics_process(delta) -> void:
	# handle _p1_ inputs
	var up_force_input = 0
	if Input.is_action_pressed("p1_thrust_up"):
		up_force_input = 1
	if Input.is_action_pressed("p1_thurst_down"):
		up_force_input = -1
		
	if up_force_input == 0:
		if not auto_float:
			auto_float_target_altitude = global_position.y
			auto_float = true
			auto_float_force = 0
	else:
		auto_float = false
		apply_force(Vector3.UP * upward_power * delta * up_force_input)
		
	
	var side_force_input = 0
	if Input.is_action_pressed("p1_thrust_right"):
		side_force_input = 1
	if Input.is_action_pressed("p1_thurst_left"):
		side_force_input = -1
		
	if side_force_input != 0:
		apply_force(Vector3.RIGHT * sideward_power * delta * side_force_input)
		
	var forward_force_input = 0
	if Input.is_action_pressed("p1_thrust_forward"):
		forward_force_input = 1
	if Input.is_action_pressed("p1_thurst_backward"):
		forward_force_input = -1
		
	if forward_force_input != 0:
		apply_force(Vector3.FORWARD * forward_power * delta * forward_force_input)
	
	
	
	## AUTO FLOAT SYSTEM
	if auto_float:
		var multi = 1
		# check downward speed and apply up force
		if global_position.y < auto_float_target_altitude:
			# slowdown when closer than 10 and going up
			var missing = auto_float_target_altitude - global_position.y

			if missing < 10:
				multi = missing / 10.0;
			if missing > 0:
				auto_float_force = lerp(auto_float_force, auto_float_power_max, 0.8)
			
		else:
			auto_float_force *= 0.5
		
		if linear_velocity.y < 0:
			multi *= 1#4
		apply_force(Vector3.UP * auto_float_force * multi)
		auto_float_force *= 0.9
	# clamp up speed
	linear_velocity = Vector3(
		clamp(linear_velocity.x, -max_x_speed, max_x_speed),
		clamp(linear_velocity.y, -max_y_speed, max_y_speed),
		clamp(linear_velocity.z, -max_z_speed, max_z_speed))
	propellit.set_speeds(abs(linear_velocity.length()) + 2)
	infotext.text = "Altitude: %.2f\nAltitude target: %.2f\nLinVelY: %.2f\nInput up: %.1f" % [global_position.y, auto_float_target_altitude, linear_velocity.y, up_force_input]
