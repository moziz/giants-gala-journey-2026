extends MeshInstance3D

@onready var pyssy = $"../Pyssy"

func _ready():
	mesh = mesh.duplicate(true)

func _process(delta):
	visible = !pyssy.ei_valintaa
	var col :Color= pyssy.valittu_color
	col.a = 0.5
	mesh.surface_get_material(0).albedo_color = col
