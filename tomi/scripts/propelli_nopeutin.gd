extends Node3D
@onready var rotator_a: Node = get_node("Propelli1")
@onready var rotator_b: Node = get_node("Propelli2")
@export var rotation_speeda: float = 2.0 # radians per second
@export var rotation_speedb: float = -2.137 # radians per second

func set_speeds(speed: float) -> void:
	rotator_a.rotation_speed = rotation_speeda * speed
	rotator_b.rotation_speed = rotation_speedb * speed
