extends Control

@onready var pelaajien_ymparisto = $"../../Maailma/PelaajienYmparisto"
@onready var maalisisus = $Maalisisus
@onready var maalikehys = $Kehys

enum ToolType {
	PAINT,
	OBJECT
}

static var vari_paletit := [
	[Color("22bed5"), Color("c6d7c8"), Color("c6d7c8"), Color("22bed5"), Color("eab5ad")],
	[Color("f26f19"), Color("fdffde"), Color("52190a"), Color("e74a4a"), Color("8aab26")],
	[Color("52190a"), Color("52190a"), Color("ffba00"), Color("22bed5"), Color("e74a4a")],
	[Color("e74a4a"), Color("52190a"), Color("fdffde"), Color("ffba00"), Color("0a0914")],
	[Color("ffba00"), Color("fdffde"), Color("fdffde"), Color("fdffde"), Color("ffba00")],
]
static var obu_paletit := [
	[preload("res://riku/koristeet/pitsi.tscn"), preload("res://riku/koristeet/pitsi.tscn"), null, null, null ],
	[null, null, preload("res://riku/koristeet/pilvi.tscn"), preload("res://riku/koristeet/kukka.tscn"), preload("res://riku/koristeet/lehti.tscn") ],
	[null, preload("res://riku/koristeet/viikset.tscn"), preload("res://riku/koristeet/pitsi3.tscn"), null, null ],
	[preload("res://riku/koristeet/kukka.tscn"), preload("res://riku/koristeet/pilvi.tscn"), preload("res://riku/koristeet/ketju.tscn"), null, null ],
	[null, null, preload("res://riku/koristeet/pitsi2.tscn"), preload("res://riku/koristeet/kaulus.tscn"), preload("res://riku/koristeet/ketju.tscn")],
]

var kopterit :Array[KopterimmeSimppeli]= []
@export var tool_index :int= 0

func _ready():
	if Engine.is_editor_hint():
		return
	var paint_colors = vari_paletit[Jattilaiset.NYKY_JATTI_INDKESI]
	var objektit = obu_paletit[Jattilaiset.NYKY_JATTI_INDKESI]
	maalisisus.self_modulate = paint_colors[tool_index]
	for child in pelaajien_ymparisto.get_children():
		if child is not KopterimmeSimppeli:
			continue
		kopterit.push_back(child)


func _process(delta):
	var paint_colors = vari_paletit[Jattilaiset.NYKY_JATTI_INDKESI]
	var objektit = obu_paletit[Jattilaiset.NYKY_JATTI_INDKESI]
	if Jattilaiset.end_countdown > 1:
		var l := 1 - pow(0.001, delta)
		modulate.a = lerpf(modulate.a, 0, l)
		return

	if Jattilaiset.LOPUN_ALKU:
		return

	var paint_color := Color.WHITE
	if tool_index < paint_colors.size():
		paint_color = paint_colors[tool_index]
	maalisisus.self_modulate = paint_color
	var objekti :PackedScene= null
	if tool_index < objektit.size():
		objekti = objektit[tool_index]

	for kopteri in kopterit:
		var screen_pos :Vector2= get_viewport().get_camera_3d().unproject_position(kopteri.global_position)
		if get_rect().has_point(screen_pos):
			var pyssy :Pyssy= kopteri.find_child("Pyssy")
			if !pyssy:
				push_error("Kopterilla ei oo Pyssy lasta")
				continue
			if !objekti:
				pyssy.maali_valittu(paint_color)
			else:
				pyssy.objekti_valittu(objekti, paint_color)
