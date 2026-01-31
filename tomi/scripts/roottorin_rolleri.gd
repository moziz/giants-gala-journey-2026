extends MeshInstance3D

@export var rotation_speed: float = 1.0 # radians per second

func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)
