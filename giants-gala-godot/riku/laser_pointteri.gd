extends MeshInstance3D

@onready var pyssy = $"../Pyssy"
@onready var mat :StandardMaterial3D= StandardMaterial3D.new()

func _process(delta):
	mat.albedo_color = pyssy.current_color
	mat.albedo_color.a = 0.5
	mesh.surface_set_material(0, mat)
